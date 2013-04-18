require 'spec_helper'

describe 'User-defined validator' do
  let(:validator) do
    unless defined?(HashValidator::Validator::OddValidator)
      # Define our custom validator
      class HashValidator::Validator::OddValidator < HashValidator::Validator::Base
        def initialize
          super('odd')
        end

        def validate(key, value, validations, errors)
          unless value.is_a?(Integer) && value.odd?
            errors[key] = presence_error_message
          end
        end
      end
    end

    HashValidator::Validator::OddValidator.new
  end

  let(:errors) { Hash.new }


  describe '#should_validate?' do
    it 'validates the name "odd"' do
      validator.should_validate?('odd').should be_true
    end

    it 'does not validate other names' do
      validator.should_validate?('string').should be_false
      validator.should_validate?('array').should  be_false
      validator.should_validate?(nil).should      be_false
    end
  end

  describe '#validate' do
    it 'validates odd integers with true' do
      validator.validate(:key, 1, {}, errors)

      errors.should be_empty
    end

    it 'validates even integers with errrors' do
      validator.validate(:key, 2, {}, errors)

      errors.should_not be_empty
      errors.should eq({ key: 'odd required' })
    end

    it 'validates even floats with errrors' do
      validator.validate(:key, 2.0, {}, errors)

      errors.should_not be_empty
      errors.should eq({ key: 'odd required' })
    end

    it 'validates odd floats with errrors' do
      validator.validate(:key, 1.0, {}, errors)

      errors.should_not be_empty
      errors.should eq({ key: 'odd required' })
    end

    it 'validates an odd integer string with errrors' do
      validator.validate(:key, '1', {}, errors)

      errors.should_not be_empty
      errors.should eq({ key: 'odd required' })
    end
  end

  describe 'Integrating with the entire validation system' do
    before { HashValidator.append_validator(validator) rescue nil }  # rescue to prevent: validators need to have unique names

    it 'can be looked up using #validator_for' do
      HashValidator.validator_for('odd').should be_a_kind_of(HashValidator::Validator::OddValidator)
    end

    it 'can be used in validations - test 1' do
      validator = HashValidator.validate({ age: 27 }, { age: 'odd' })

      validator.valid?.should be_true
      validator.errors.should be_empty
    end

    it 'can be used in validations - test 2' do
      validator = HashValidator.validate({ age: 40 }, { age: 'odd' })

      validator.valid?.should be_false
      validator.errors.should eq({ age: 'odd required' })
    end
  end
end
