module MarchHare
  class ForgivingExceptionHandler < com.rabbitmq.client.impl.ForgivingExceptionHandler
    include RubifyJavaExceptionHandler
  end
end