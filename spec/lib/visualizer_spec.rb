RSpec.describe Deps::Visualizer do
  describe '.draw' do
    let(:graph_svg) do
      <<~EOF
        <!-- Site -->
        <g id="node1" class="node">
        <title>Site</title>
        <ellipse fill="none" stroke="black" cx="34.45" cy="-90" rx="27" ry="18"/>
        <text text-anchor="middle" x="34.45" y="-86.3" font-family="Times,serif" font-size="14.00">Site</text>
        </g>
        <!-- Person -->
        <g id="node2" class="node">
        <title>Person</title>
        <ellipse fill="none" stroke="black" cx="34.45" cy="-18" rx="34.39" ry="18"/>
        <text text-anchor="middle" x="34.45" y="-14.3" font-family="Times,serif" font-size="14.00">Person</text>
        </g>
        <!-- Site&#45;&gt;Person -->
        <g id="edge1" class="edge">
        <title>Site&#45;&gt;Person</title>
        <path fill="none" stroke="black" d="M34.45,-71.7C34.45,-63.98 34.45,-54.71 34.45,-46.11"/>
        <polygon fill="black" stroke="black" points="37.95,-46.1 34.45,-36.1 30.95,-46.1 37.95,-46.1"/>
        </g>
      EOF
    end
    let(:file_path) { File.expand_path('deps.svg') }

    context 'when graph present' do
      subject { described_class.draw([['Site', 'Person']]) }

      after do
        File.delete(file_path) if File.exist?(file_path)
      end

      it 'call GraphViz#output' do
        expect_any_instance_of(GraphViz).to receive(:output)
        subject
      end

      it 'creates graph image' do
        subject
        expect(File.read(file_path)).to include(graph_svg)
      end

      it 'creates graph in the correct path' do
        subject
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
