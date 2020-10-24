require 'ruby-graphviz'

# TODO: Filter by path
# TODO: Filter by class with stack size
# TODO: meta programming
class Deps
  attr_reader :stack_level

  def self.run
    self.test_run { yield }.tap { |deps| deps.create_graph_image }
  end

  def self.test_run
    deps = Deps.new
    @trace1 = TracePoint.new(:call) do |tp|
      class_name = tp.defined_class.to_s
      method = tp.method_id.to_s
      deps.change_stack_level_by(1)
      # deps.ascend_stack_level
      deps.add_callee(class_name, method)
    end
    @trace2 = TracePoint.new(:return) do |tp|
      deps.match_dependency
      # deps.descend_stack_level
      deps.change_stack_level_by(-1)
    end
    @trace1.enable
    @trace2.enable
    yield
    @trace1.disable
    @trace2.disable
    deps
  end

  def initialize
    @callees = []
    @deps = []
    @stack_level = 0
  end

  def add_callee(called_class, method)
    @callees.prepend [called_class, method, stack_level]
  end

  def match_dependency
    add_dep(find_caller, latest_called) if find_caller
  end

  def previous_stack_level
    stack_level - 1
  end

  def find_caller
    @callees.find do |called_pair|
      called_pair.last == previous_stack_level
    end
  end

  def latest_called
    @callees.find do |called_pair|
      called_pair.last == stack_level
    end
  end

  def add_dep(caller_triple, called_triple)
    @deps << [caller_triple, called_triple]
  end

  def dependency_graph
    @deps.map do |a, b|
      [a[0..1].join('#'), b[0..1].join('#')]
    end.uniq
  end

  def class_graph
    @deps.map { |a, b| [a.first, b.first] }.uniq.reject { |klass1, klass2| klass1 == klass2 }
  end

  def change_stack_level_by(number)
    @stack_level += number
  end

  def create_graph_image
    return if dependency_graph.empty?

    g = GraphViz.new('Deps')
    dependency_graph.each do |k, vs|
      n1 = g.add_nodes(k)
      n2 = g.add_nodes(vs)
      g.add_edges(n1, n2)
    end
    g.output(png: 'deps.png')
  end

  class Visualizer
    def self.draw(graph)
      return if graph.empty?

      g = GraphViz.new('Deps')
      graph.each do |k, vs|
        n1 = g.add_nodes(k)
        n2 = g.add_nodes(vs)
        g.add_edges(n1, n2)
      end
      g.output(svg: 'deps.svg')
    end
  end
end
