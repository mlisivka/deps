require 'ruby-graphviz'

# TODO: Filter by class with stack size
# TODO: meta programming
# TODO: excluding classes - array of regexep or string
# TODO: if object passed as argument - no dependency
# TODO: chose which graph create: class or method - switch on the fly
# TODO: c_retrun, c_call
# TODO: singleton class divider - .
class Deps
  attr_reader :stack_level

  def self.run(klass: true, **opts, &block)
    test_run(opts, &block).tap do |deps|
      Visualizer.draw(klass ? deps.class_graph : deps.dependency_graph, format: :svg)
    end
  end

  def self.test_run(filter: nil)
    deps = Deps.new
    allowed_path = Dir.glob(File.expand_path(filter)) if filter
    @trace1 = TracePoint.new(:call) do |tp|
      next deps.ascend_stack_level if allowed_path && !allowed_path.include?(tp.path)

      class_name = tp.defined_class.to_s.delete_prefix('#<Class:').delete_suffix('>').split('(').first
      method = tp.method_id.to_s
      deps.ascend_stack_level
      deps.add_callee(class_name, method)
    end
    @trace2 = TracePoint.new(:return) do |tp|
      next deps.descend_stack_level if allowed_path && !allowed_path.include?(tp.path)

      puts tp.path
      deps.match_dependency
      deps.descend_stack_level
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

  def ascend_stack_level
    @stack_level += 1
  end

  def descend_stack_level
    @stack_level -= 1
  end

  def change_stack_level_by(number)
    @stack_level += number
  end

  def dependency_graph
    @deps.reject { |a| a.compact.size < 2 || a.first == a.second }.map do |a, b|
      [a[0..1].join('#'), b[0..1].join('#')]
    end.uniq.reject do |method1, method2|
      klass1 = method1.split('#').first
      klass2 = method2.split('#').first
      klass1 == 'ApplicationRecord' || klass2 == 'ApplicationRecord' ||
        klass1 == 'DatabaseUtils' || klass2 == 'DatabaseUtils' ||
        klass1 == 'XssPrevention' || klass2 == 'XssPrevention' ||
        klass1 == 'JoinedAttributes' || klass2 == 'JoinedAttributes'
    end
  end

  def class_graph
    @deps.reject { |a| a.compact.uniq.size < 2 }.map do |a, b|
      [a.first, b.first]
    end.uniq.reject do |klass1, klass2|
      klass1 == 'ApplicationRecord' || klass2 == 'ApplicationRecord' ||
        klass1 == 'DatabaseUtils' || klass2 == 'DatabaseUtils' ||
        klass1 == 'XssPrevention' || klass2 == 'XssPrevention' ||
        klass1 == 'JoinedAttributes' || klass2 == 'JoinedAttributes'
    end
  end

  private

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

  class Visualizer
    def self.draw(graph, format: :svg)
      return if graph.empty?

      g = GraphViz.new('Deps')
      graph.each do |k, vs|
        n1 = g.add_nodes(k)
        n2 = g.add_nodes(vs)
        g.add_edges(n1, n2)
      end
      g.output(format => "deps.#{format}")
    end
  end
end
