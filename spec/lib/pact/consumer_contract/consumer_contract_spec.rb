require 'spec_helper'
require 'pact/consumer_contract'

module Pact
  describe ConsumerContract do

    describe ".from_json" do
      let(:loaded_pact) { ConsumerContract.from_json(string) }
      context "when the top level object is a ConsumerContract" do
        let(:string) { '{"interactions":[{"request": {"path":"/path", "method" : "get"}, "response": {"status" : 200}}], "consumer": {"name" : "Bob"} , "provider": {"name" : "Mary"} }' }

        it "should create a Pact" do
          expect(loaded_pact).to be_instance_of ConsumerContract
        end

        it "should have interactions" do
          expect(loaded_pact.interactions).to be_instance_of Array
        end

        it "should have a consumer" do
          expect(loaded_pact.consumer).to be_instance_of Pact::ServiceConsumer
        end

        it "should have a provider" do
          expect(loaded_pact.provider).to be_instance_of Pact::ServiceProvider
        end
      end

      context "with old 'producer' key" do
        let(:string) { File.read('./spec/support/a_consumer-a_producer.json')}
        it "should create a Pact" do
          expect(loaded_pact).to be_instance_of ConsumerContract
        end

        it "should have interactions" do
          expect(loaded_pact.interactions).to be_instance_of Array
        end

        it "should have a consumer" do
          expect(loaded_pact.consumer).to be_instance_of Pact::ServiceConsumer
        end

        it "should have a provider" do
          expect(loaded_pact.provider).to be_instance_of Pact::ServiceProvider
          expect(loaded_pact.provider.name).to eq "an old producer"
        end

        it "should have a provider_state" do
          expect(loaded_pact.interactions.first.provider_state).to eq 'state one'
        end
      end
    end

    describe "find_interactions" do
      let(:consumer) { double('Pact::ServiceConsumer', :name => 'Consumer')}
      let(:provider) { double('Pact::ServiceProvider', :name => 'Provider')}
      let(:interaction) { double('Pact::Interaction') }
      subject { ConsumerContract.new(:interactions => [interaction], :consumer => consumer, :provider => provider) }
      let(:criteria) { {:description => /blah/} }
      before do
        expect(interaction).to receive(:matches_criteria?).with(criteria).and_return(matches)
      end
      context "by description" do
        context "when no interactions are found" do
          let(:matches) { false }
          it "returns an empty array" do
            expect(subject.find_interactions(criteria)).to eql []
          end
        end
        context "when interactions are found" do
          let(:matches) { true }
          it "returns an array of the matching interactions" do
            expect(subject.find_interactions(criteria)).to eql [interaction]
          end
        end
      end
    end

    describe "find_interaction" do
      let(:consumer) { double('Pact::ServiceConsumer', :name => 'Consumer')}
      let(:provider) { double('Pact::ServiceProvider', :name => 'Provider')}
      let(:interaction1) { double('Pact::Interaction') }
      let(:interaction2) { double('Pact::Interaction') }
      let(:criteria) { {:description => /blah/} }

      before do
        expect(interaction1).to receive(:matches_criteria?).with(criteria).and_return(matches1)
        expect(interaction2).to receive(:matches_criteria?).with(criteria).and_return(matches2)
      end

      subject { ConsumerContract.new(:interactions => [interaction1, interaction2], :consumer => consumer, :provider => provider) }
      context "by description" do
        context "when a match is found" do
          let(:matches1) { true }
          let(:matches2) { false }

          it "returns the interaction" do
            expect(subject.find_interaction criteria).to eql interaction1
          end
        end
        context "when more than one match is found" do
          let(:matches1) { true }
          let(:matches2) { true }
          it "raises an error" do
            expect{ subject.find_interaction(criteria) }.to raise_error "Found more than 1 interaction matching {:description=>/blah/} in pact file between Consumer and Provider."
          end
        end
        context "when a match is not found" do
          let(:matches1) { false }
          let(:matches2) { false }
          it "raises an error" do
            expect{ subject.find_interaction(criteria) }.to raise_error "Could not find interaction matching {:description=>/blah/} in pact file between Consumer and Provider."
          end
        end
      end
    end

    describe ".get_response_contract" do
      let(:consumer) { double('Pact::ServiceConsumer', :name => 'my consumer')}
      let(:provider) { double('Pact::ServiceProvider', :name => 'my provider')}
      let(:response) { { body: Pact::SomethingLike.new('my body') } }
      let(:interaction) { double('Pact::Interaction', response: response, provider_state: 'my state') }
      let(:contract) { ConsumerContract.new(interactions: [interaction], consumer: consumer, provider: provider) }
      let(:pact_borker_uri) { URI("http://pact-broker/pacts/provider/my%20provider/consumer/my%20consumer/latest") }
      subject { described_class.get_response_contract("my provider", "my consumer", state) }

      before do
        expect(Pact::ConsumerContract).to receive(:from_uri).with(pact_borker_uri).and_return(contract)
      end

      context "state exist" do
        let(:state) { "my state" }
        it 'returns respose contract' do
          expect(subject).to be_instance_of(Pact::SomethingLike)
        end
      end

      context "state does not exist" do
        let(:state) { "dummy state" }
        it "fails" do
          expect { subject }.to raise_error
        end
      end
    end

    describe ".get_response_sample" do
      let(:consumer) { double('Pact::ServiceConsumer', :name => 'my consumer')}
      let(:provider) { double('Pact::ServiceProvider', :name => 'my provider')}
      let(:response) { { body: Pact::SomethingLike.new('my body') } }
      let(:interaction) { double('Pact::Interaction', response: response, provider_state: 'my state') }
      let(:contract) { ConsumerContract.new(interactions: [interaction], consumer: consumer, provider: provider) }
      let(:pact_borker_uri) { URI("http://pact-broker/pacts/provider/my%20provider/consumer/my%20consumer/latest") }
      subject { described_class.get_response_sample("my provider", "my consumer", state) }

      before do
        expect(Pact::ConsumerContract).to receive(:from_uri).with(pact_borker_uri).and_return(contract)
      end

      context "state exist" do
        let(:state) { "my state" }
        it 'returns respose contract' do
          expect(subject).to eq('my body')
        end
      end

      context "state does not exist" do
        let(:state) { "dummy state" }
        it "fails" do
          expect { subject }.to raise_error
        end
      end
    end

    describe ".pact_broker_url" do
      it 'is private and not accessible' do
        expect { Pact::ConsumerContract.pact_broker_url('foo', 'bar') }.to raise_error(NoMethodError)
      end
    end
  end
end
