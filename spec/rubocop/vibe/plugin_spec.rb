# frozen_string_literal: true

RSpec.describe RuboCop::Vibe::Plugin do
  subject(:plugin) { described_class.new }

  describe "#about" do
    subject(:about) { plugin.about }

    it { is_expected.to have_attributes(name: "rubocop-vibe", version: RuboCop::Vibe::VERSION) }
  end

  describe "#supported?" do
    subject(:supported) { plugin.supported?(context) }

    let(:context) { double(engine: engine) }

    context "when engine is rubocop" do
      let(:engine) { :rubocop }

      it { is_expected.to be(true) }
    end

    context "when engine is not rubocop" do
      let(:engine) { :other }

      it { is_expected.to be(false) }
    end
  end

  describe "#rules" do
    subject(:rules) { plugin.rules(double) }

    it { is_expected.to have_attributes(type: :path, config_format: :rubocop) }
  end
end
