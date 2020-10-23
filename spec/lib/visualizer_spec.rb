RSpec.describe Deps::Visualizer do
  describe '.draw' do
    let(:file_path) { File.expand_path('deps.png') }

    context 'when graph present' do
      after do
        File.delete(file_path) if File.exist?(file_path)
      end

      it 'call GraphViz#output' do
        expect_any_instance_of(GraphViz).to receive(:output)
        described_class.draw(['Site', 'Person'])
      end

      it 'creates graph image' do
        described_class.draw(['Site', 'Person'])
        expect(File.exist?(file_path)).to be_truthy
      end
    end

    context 'when graph is empty' do
      it 'does not create graph image' do
        described_class.draw([])
        expect(File.exist?(file_path)).to be_falsey
      end
    end
  end
end
