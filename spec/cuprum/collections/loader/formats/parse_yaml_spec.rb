# frozen_string_literal: true

require 'cuprum/collections/loader/formats/parse_yaml'

RSpec.describe Cuprum::Collections::Loader::Formats::ParseYaml do
  subject(:command) { described_class.new(**constructor_options) }

  let(:constructor_options) { {} }

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:options)
    end
  end

  describe '#call' do
    it { expect(command).to be_callable.with(1).argument }

    describe 'with nil' do
      let(:expected_error) do
        Cuprum::Collections::Loader::Errors::ParseError.new(
          format:    :yaml,
          raw_value: nil
        )
      end

      it 'should return a failing result' do
        expect(command.call(nil))
          .to be_a_failing_result
          .with_error(expected_error)
      end
    end

    describe 'with an Object' do
      let(:object) { Object.new.freeze }
      let(:expected_error) do
        Cuprum::Collections::Loader::Errors::ParseError.new(
          format:    :yaml,
          raw_value: object
        )
      end

      it 'should return a failing result' do
        expect(command.call(object))
          .to be_a_failing_result
          .with_error(expected_error)
      end
    end

    describe 'with an empty string' do
      let(:expected_error) do
        Cuprum::Collections::Loader::Errors::DataError.new(
          format:       :yaml,
          parsed_value: nil,
          raw_value:    ''
        )
      end

      it 'should return a failing result' do
        expect(command.call(''))
          .to be_a_failing_result
          .with_error(expected_error)
      end
    end

    describe 'with an invalid YAML String' do
      let(:string) do
        <<~YAML
          ---
          test: - nope
        YAML
      end
      let(:expected_message) do
        YAML.safe_load(string)
      rescue Psych::SyntaxError => exception
        exception.message
      end
      let(:expected_error) do
        Cuprum::Collections::Loader::Errors::ParseError.new(
          format:    :yaml,
          message:   expected_message,
          raw_value: string
        )
      end

      it 'should return a failing result' do
        expect(command.call(string))
          .to be_a_failing_result
          .with_error(expected_error)
      end
    end

    describe 'with an unsafe YAML String' do
      let(:string) do
        <<~YAML
          default: &default
            adapter: /dev/null

          development:
            <<: *default
        YAML
      end
      let(:expected_message) do
        YAML.safe_load(string)
      rescue Psych::BadAlias => exception
        exception.message
      end
      let(:expected_error) do
        Cuprum::Collections::Loader::Errors::ParseError.new(
          format:    :yaml,
          message:   expected_message,
          raw_value: string
        )
      end

      it 'should return a failing result' do
        expect(command.call(string))
          .to be_a_failing_result
          .with_error(expected_error)
      end
    end

    describe 'with a YAML String that parses to an invalid value' do
      let(:string) do
        <<~YAML
          ---
          invalid value
        YAML
      end
      let(:expected_error) do
        Cuprum::Collections::Loader::Errors::DataError.new(
          format:       :yaml,
          parsed_value: 'invalid value',
          raw_value:    string
        )
      end

      it 'should return a failing result' do
        expect(command.call(string))
          .to be_a_failing_result
          .with_error(expected_error)
      end
    end

    describe 'with a YAML String that parses to an invalid array' do
      let(:string) do
        <<~YAML
          ---
          - invalid value
        YAML
      end
      let(:expected_error) do
        Cuprum::Collections::Loader::Errors::DataError.new(
          format:       :yaml,
          parsed_value: ['invalid value'],
          raw_value:    string
        )
      end

      it 'should return a failing result' do
        expect(command.call(string))
          .to be_a_failing_result
          .with_error(expected_error)
      end
    end

    describe 'with a YAML String that parses to an empty Array' do
      let(:string) do
        <<~YAML
          ---
          []
        YAML
      end
      let(:expected) { [] }

      it 'should parse the YAML' do
        expect(command.call(string))
          .to be_a_passing_result
          .with_value(expected)
      end
    end

    describe 'with a YAML String that parses to an Array of data Hashes' do
      let(:string) do
        <<~YAML
          ---
          - name:       Red
            generation: 1
          - name:       Gold
            generation: 2
          - name:       Ruby
            generation: 3
        YAML
      end
      let(:expected) do
        [
          {
            'name'       => 'Red',
            'generation' => 1
          },
          {
            'name'       => 'Gold',
            'generation' => 2
          },
          {
            'name'       => 'Ruby',
            'generation' => 3
          }
        ]
      end

      it 'should parse the YAML' do
        expect(command.call(string))
          .to be_a_passing_result
          .with_value(expected)
      end
    end

    describe 'with a YAML String that parses to an empty Hash' do
      let(:string) do
        <<~YAML
          ---
          {}
        YAML
      end
      let(:expected) { {} }

      it 'should parse the YAML' do
        expect(command.call(string))
          .to be_a_passing_result
          .with_value(expected)
      end
    end

    describe 'with a YAML String that parses to a data Hash' do
      let(:string) do
        <<~YAML
          ---
          name: Self-Sealing Stem Bolt
          purpose: |
            Nobody actually knows what the purpose of this object is, but you
            won't find a better stem bolt anywhere in the quadrant.
        YAML
      end
      let(:expected) do
        {
          'name'    => 'Self-Sealing Stem Bolt',
          'purpose' => 'Nobody actually knows what the purpose of this object' \
                       " is, but you won't find a better stem bolt anywhere" \
                       ' in the quadrant.'
        }
      end

      it 'should parse the YAML' do
        expect(command.call(string))
          .to be_a_passing_result
          .with_value(expected)
      end
    end

    describe 'with a YAML String with a multi-line String value' do
      let(:string) do
        <<~YAML
          ---
          name: Self-Sealing Stem Bolt
          purpose: |
            Nobody actually knows what the purpose of this object is, but you
            won't find a better stem bolt anywhere in the quadrant.
          features: |
            The Self-Sealing Stem Bolt comes with the following features:

            - It's Quality Merchandise.
            - It's a Stem Bolt.
            - It's Self-Sealing.
        YAML
      end
      let(:expected) do
        {
          'name'     => 'Self-Sealing Stem Bolt',
          'purpose'  => 'Nobody actually knows what the purpose of this' \
                        " object is, but you won't find a better stem bolt" \
                        ' anywhere in the quadrant.',
          'features' => 'The Self-Sealing Stem Bolt comes with the following' \
                        " features: - It's Quality Merchandise. - It's a Stem" \
                        " Bolt. - It's Self-Sealing."
        }
      end

      it 'should parse the YAML' do
        expect(command.call(string))
          .to be_a_passing_result
          .with_value(expected)
      end
    end

    context 'when initialized with options' do
      let(:options)             { { 'features' => { 'multiline' => true } } }
      let(:constructor_options) { super().merge(options: options) }

      describe 'with a YAML String with a multi-line String value' do
        let(:string) do
          <<~YAML
            ---
            name: Self-Sealing Stem Bolt
            purpose: |
              Nobody actually knows what the purpose of this object is, but you
              won't find a better stem bolt anywhere in the quadrant.
            features: |
              The Self-Sealing Stem Bolt comes with the following features:

              - It's Quality Merchandise.
              - It's a Stem Bolt.
              - It's Self-Sealing.
          YAML
        end
        let(:expected) do
          {
            'name'     => 'Self-Sealing Stem Bolt',
            'purpose'  => 'Nobody actually knows what the purpose of this' \
                          " object is, but you won't find a better stem bolt" \
                          ' anywhere in the quadrant.',
            'features' => <<~RAW.strip
              The Self-Sealing Stem Bolt comes with the following features:

              - It's Quality Merchandise.
              - It's a Stem Bolt.
              - It's Self-Sealing.
            RAW
          }
        end

        it 'should parse the YAML' do
          expect(command.call(string))
            .to be_a_passing_result
            .with_value(expected)
        end
      end
    end
  end

  describe '#options' do
    include_examples 'should define reader', :options, {}

    context 'when initialized with options' do
      let(:options)             { { 'features' => { 'multiline' => true } } }
      let(:constructor_options) { super().merge(options: options) }

      it { expect(command.options).to be == options }
    end
  end
end
