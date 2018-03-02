defmodule ExCraft.Car do
  require ExCraft
  ExCraft.craft [
    %{name: :brand,  type: :string,        required: false,   default: "custom"},
    %{name: :year,   type: :pos_integer,   required: true,    default: nil},
    %{name: :used,   type: :boolean,       required: false,   default: true},
  ]
end
