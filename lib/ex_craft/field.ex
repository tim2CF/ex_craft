defmodule ExCraft.Field do

  @doc """
  Field properties in struct constructor
  """

  @fields [:name, :type, :required, :default, :enforce]
  @enforce_keys @fields
  defstruct     @fields
end
