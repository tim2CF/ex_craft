defmodule ExCraft.Field do
  @moduledoc """
  Field properties in struct constructor
  """
  @fields [:name, :type, :required, :default, :enforce]
  @enforce_keys @fields
  defstruct     @fields
end
