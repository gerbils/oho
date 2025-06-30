class TestJob < ApplicationJob
  queue_as :default

  def perform(count_id)
    logger.info("starting test job")
    counter = Test.find(count_id)
    while counter.count > 0
      sleep(1)
      logger.info("decrementing count: #{counter.count}")
      counter.count -= 1
      counter.save!
    end
    logger.info("finishing job")
  end
end
