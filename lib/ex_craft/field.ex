defmodule ExCraft.Field do
  @fields [:name, :type, :required, :default]
  @enforce_keys @fields
  defstruct     @fields
end
