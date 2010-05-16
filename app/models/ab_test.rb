class AbTest < ActiveRecord::Base
  class << self
    def load_all
      AbTest.all.each do |ab_test|
        ab_test.load
      end
    end
  end

  belongs_to :metric, :class_name => 'DbMetric'

  validates_presence_of :name
  validates_presence_of :metric

  after_create :load

  def load
    experiment = self.experiment
    experiment.save
    Vanity.playground.experiments[experiment_id] = experiment
  end

  def experiment_id
    name.parameterize.to_s.underscore.to_sym unless new_record?
  end

  def experiment
    @experiment ||= begin
      experiment = Vanity::Experiment::AbTest.new(Vanity.playground, experiment_id, name)
      experiment.description(self.description)
      experiment.metrics(metric.metric_id)
      experiment
    end
  end

  def available_metrics
    DbMetric.all
  end
end