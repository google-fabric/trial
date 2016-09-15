# Trial!

A Ruby library for trialing new systems that may still fail.

This is heavily based on the fantastic gem by the awesome people at Github called scientist: https://github.com/github/scientist/blob/master/README.md

## Why use trial instead of scientist?

Trial is a tool we built as a natural successor to scientist.

It is not intended as a replacement for scientist, but rather a next step between running scientist experiments and firmly committing your new code to the production critical path.

In other words, we recommend you start by using scientist to refactor.  But when you're convinced your new system or code is ready for primetime, trial can help you start using your new system with a safe fallback to the old system.

Trial lets you specify two codepaths: the new system, and the fallback system.  It will attempt to run the new system, and if any unexpected exceptions occur, it will fall back to the old system.

The primary advantage it offers over scientist is that it doesn't by default incur the latency hit of running both the old & new systems.  It only runs both if the new system fails.

## How do I use it?

Let's say you have two systems that compute metrics.  You are close to cutting over all your production traffic to use the new one, but you still want to make sure your customers aren't impacted if the new system has any unexpected problems or glitches.  Trial lets you try the new system but fall back to the old system if any exceptions happen.

```ruby
require 'trial'

class MyWidget
  include Trial

  def compute_metrics
    attempt('new_auth_system') do |attempt|
      attempt.try { new_system.compute_metrics }
      attempt.fallback { old_system.compute_metrics }
    end
  end
end

```

It will _only_ run the fallback if the new system has a failure.