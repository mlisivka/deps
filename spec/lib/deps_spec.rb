require './lib/deps'

RSpec.describe Deps do
  describe '.run' do
    let(:file_path) { File.expand_path('deps.png') }

    context 'when dependency_graph present' do
      class Person
        def phone_number
          PhoneNumber.new.phone
        end
      end
      class PhoneNumber
        def phone
          '+3809876543210'
        end
      end

      after do
        File.delete(file_path)
      end

      it 'creates graph image' do
        Deps.run do
          Person.new.phone_number
        end
        expect(File.exist?(file_path)).to be_truthy
      end
    end

    context 'when dependency_graph is empty' do
      it 'does not create graph image' do
        Deps.run do
        end
        expect(File.exist?(file_path)).to be_falsey
      end
    end
  end

  context 'when there is no dependency' do
    class Person
      def first_name
        'Hello'
      end
    end
    let(:deps) do
      Deps.test_run do
        person = Person.new
        person.first_name
      end
    end

    describe 'method graph' do
      it do
        expect(deps.dependency_graph).to eq []
      end
    end

    describe 'class graph' do
      it do
        expect(deps.class_graph).to eq []
      end
    end
  end

  context 'with simple dependency' do
    class Person
      def first_name
        'Hello'
      end

      def phone_number
        PhoneNumber.new.phone
      end
    end
    class PhoneNumber
      def phone
        '+3809876543210'
      end
    end
    let(:deps) do
      Deps.test_run do
        person = Person.new
        person.first_name
        person.phone_number
      end
    end

    describe 'method graph' do
      it do
        expect(deps.dependency_graph).to eq [['Person#phone_number', 'PhoneNumber#phone']]
      end
    end

    describe 'class graph' do
      it do
        expect(deps.class_graph).to eq [['Person', 'PhoneNumber']]
      end
    end
  end

  context 'with 3rd party library' do
    class Person2
      def first_name
        'Hello'
      end

      def phone_number
        PhoneNumber2.new.phone
      end
    end
    class PhoneNumber2
      require 'base64'
      def phone
        Base64.encode64('+3809876543210')
      end
    end
    subject(:deps) do
      Deps.test_run(filter: 'spec/lib/*') do
        person = Person2.new
        person.first_name
        person.phone_number
      end
    end

    context 'with filter option' do
      describe 'method graph' do
        it do
          expect(deps.dependency_graph).to eq [['Person2#phone_number', 'PhoneNumber2#phone']]
        end
      end

      describe 'class graph' do
        it do
          expect(deps.class_graph).to eq [['Person2', 'PhoneNumber2']]
        end
      end
    end
  end

  context 'with complex dependencies' do
    class Person
      def first_name
        'John'
      end

      def last_name
        'Snow'
      end

      def middle_name
        PhoneNumber.new.get
      end
    end
    module StringUtils
      def validate_str(string)
        string
      end
    end
    module NumberUtils
      include StringUtils
      def validate(number)
        validate_str(number)
      end
    end
    class PhoneNumber
      include NumberUtils

      def get
        validate_str(validate('+123'))
      end
    end
    class Site
      def initialize
        @person = Person.new
      end

      def full_name
        test
        @person.first_name + @person.middle_name + @person.last_name
      end

      def print(text)
        text
      end

      def test
        print('Nothing')
      end
    end
    let(:deps) do
      Deps.test_run do
        site = Site.new
        site.full_name
      end
    end

    describe 'method graph' do
      it do
        expect(deps.dependency_graph).to eq [
          ["Site#test", "Site#print"],
          ["Site#full_name", "Site#test"],
          ["Site#full_name", "Person#first_name"],
          ["NumberUtils#validate", "StringUtils#validate_str"],
          ["PhoneNumber#get", "NumberUtils#validate"],
          ["PhoneNumber#get", "StringUtils#validate_str"],
          ["Person#middle_name", "PhoneNumber#get"],
          ["Site#full_name", "Person#middle_name"],
          ["Site#full_name", "Person#last_name"]
        ]
      end
    end

    describe 'class graph' do
      it do
        expect(deps.class_graph).to eq [
          ["Site", "Person"],
          ["NumberUtils", "StringUtils"],
          ["PhoneNumber", "NumberUtils"],
          ["PhoneNumber", "StringUtils"],
          ["Person", "PhoneNumber"]
        ]
      end
    end
  end
end
