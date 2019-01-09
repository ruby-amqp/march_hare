module MarchHare
  class StrictExceptionHandler < com.rabbitmq.client.impl.StrictExceptionHandler
    include RubifyJavaExceptionHandler
  end
end