module MetricTags
  include Radiant::Taggable

  def self.included(mod)
    mod.class_eval do
      alias_method_chain :process, :vanity
    end
  end

  # Process page after setting Vanity context
  def process_with_vanity(*args)
    Vanity.context = self
    process_without_vanity(*args)
  end

  # Identify user for vanity
  def vanity_identity
    if response
      jar = ActionController::CookieJar.new(self)
      @vanity_identity = jar['vanity_id'] || ActiveSupport::SecureRandom.hex(16)
      jar["vanity_id"] = {:value=>@vanity_identity, :expires=>1.month.from_now}
      @vanity_identity
    end
  end

  desc %{
    Increments a metric with the given name.

    *Usage:*

    <pre><code><r:track name="signup" /></code></pre>
  }
  tag 'track' do |tag|
    self.metaclass.class_eval{define_method(:cache?){false}}
    if tag.attr['name']
      Vanity.playground.track! tag.attr['name'].to_s
    end
  end

  tag 'ab' do |tag|
    self.metaclass.class_eval{define_method(:cache?){false}}
    tag.expand
  end

  desc %Q{
    Run an A/B test with the given name.

    *Usage:*

    <pre><code><r:ab:test name="homepage test">
      <r:a>Shown to A users</r:a>
      <r:b>Shown to B users</r:b>
    </r:ab:test></code></pre>
  }
  tag 'ab:test' do |tag|
    if tag.attr['name']
      ab_test = AbTest.find_by_name(tag.attr['name'])
      if ab_test
        tag.locals.experiment_id = ab_test.experiment_id
        tag.expand
      end
    end
  end

  desc "Render the contents of this tag if the experiment chooses A"
  tag 'ab:test:a' do |tag|
    experiment = Vanity.playground.experiments[tag.locals.experiment_id]
    unless experiment.choose
      tag.expand
    end
  end

  desc "Render the contents of this tag is the experiment chooses B"
  tag 'ab:test:b' do |tag|
    experiment = Vanity.playground.experiments[tag.locals.experiment_id]
    if experiment.choose
      tag.expand
    end
  end
end