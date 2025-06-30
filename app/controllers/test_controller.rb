class TestController < ApplicationController
  def index
    @count = Test.create!(count: 5)
    TestJob.perform_later(@count.id)
  end
end
