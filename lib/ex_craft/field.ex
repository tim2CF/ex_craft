defmodule ExCraft.Field do
  @fields [:name, :type, :required, :default, :enforce]
  @enforce_keys @fields
  defstruct     @fields
end
