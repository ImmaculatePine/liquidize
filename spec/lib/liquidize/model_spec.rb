require 'spec_helper'

# Helper method that converts string to the dumped representation
# @param value [String] original string
# @return [String] dump representation
def string_to_dump(value)
  parsed_value = Liquid::Template.parse(value)
  Base64.strict_encode64(Marshal.dump(parsed_value))
end

RSpec.describe Liquidize::Model do
  describe 'include' do
    shared_examples 'both' do
      it 'adds class methods' do
        expect(klass).to respond_to(:liquidize)
      end
    end

    context 'with ActiveRecord' do
      let(:klass) { Page }
      it_behaves_like 'both'
    end

    context 'with plain Ruby' do
      let(:klass) { NonActiveRecordPage }
      it_behaves_like 'both'
    end
  end

  describe '.liquidize' do
    shared_examples 'both' do
      it 'defines new instance methods' do
        expect(page).to respond_to(:liquid_body_template)
        expect(page).to respond_to(:parse_liquid_body!)
        expect(page).to respond_to(:render_body)
      end
    end

    context 'with ActiveRecord' do
      let(:page) { Page.new }
      it_behaves_like 'both'
    end

    context 'with plain Ruby' do
      let(:page) { NonActiveRecordPage.new }
      it_behaves_like 'both'
    end
  end

  describe '#render_*' do
    shared_examples 'both' do
      it 'renders valid template' do
        page.body = 'Hello, {{username}}!'
        expect(page.render_body(username: 'Alex')).to eq('Hello, Alex!')
      end
    end

    context 'with ActiveRecord' do
      let(:page) { Page.new }
      it_behaves_like 'both'
    end

    context 'with plain Ruby' do
      let(:page) { NonActiveRecordPage.new }
      it_behaves_like 'both'
    end
  end

  describe 'setter' do
    let(:valid_body) { 'Hi, {{username}}' }
    let(:invalid_body) { 'Hi, {{username' }
    let(:syntax_error_message) { "Liquid syntax error: Variable '{{' was not properly terminated with regexp: /\\}\\}/" }

    shared_examples 'both' do
      it 'still works as default setter' do
        expect { page.body = valid_body }.to change(page, :body).from(nil).to(valid_body)
      end

      it 'parses new value' do
        expect(page).to receive(:parse_liquid_body!)
        page.body = valid_body
      end

      it 'does not set @*_syntax_error instance variable with valid body' do
        page.instance_variable_set(:@body_syntax_error, nil) # prevent warning
        expect { page.body = valid_body }.not_to(change { page.instance_variable_get(:@body_syntax_error) })
      end

      it 'sets @*_syntax_error instance variable with invalid body' do
        page.instance_variable_set(:@body_syntax_error, nil) # prevent warning
        expect { page.body = invalid_body }.to change { page.instance_variable_get(:@body_syntax_error) }.from(nil).to(syntax_error_message)
      end

      it 'resets syntax error when valid value is passed' do
        page.instance_variable_set(:@body_syntax_error, nil) # prevent warning
        expect { page.body = invalid_body }.to change { page.instance_variable_get(:@body_syntax_error) }.from(nil).to(syntax_error_message)
        expect { page.body = valid_body }.to change { page.instance_variable_get(:@body_syntax_error) }.from(syntax_error_message).to(nil)
      end
    end

    context 'with ActiveRecord' do
      let(:page) { Page.new }
      it_behaves_like 'both'

      it 'sets liquid_body attribute' do
        expect { page.body = valid_body }.to change(page, :liquid_body).from(nil).to(string_to_dump(valid_body))
      end

      it 'syntaxically correct values does not make record invalid' do
        page.body = valid_body
        expect(page).to be_valid
      end

      it 'value with syntax error makes record invalid' do
        page.body = invalid_body
        expect(page).not_to be_valid
        expect(page.errors.messages).to eq(body: [syntax_error_message])
      end

      it 'does not parse body for the second time if it was already parsed and saved' do
        page = Page.create(body: valid_body)
        page_from_db = Page.find(page.id)
        expect(page_from_db).not_to receive(:parse_liquid_body!)
        render = page_from_db.render_body(username: 'Alex')
        expect(render).to eq('Hi, Alex')
      end
    end

    context 'with plain Ruby' do
      let(:page) { NonActiveRecordPage.new }
      it_behaves_like 'both'
    end
  end
end
