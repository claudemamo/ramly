module Ramly
  class RamlyError < StandardError;
  end

  class ImplementedUnknownResource < RamlyError;
  end
end
