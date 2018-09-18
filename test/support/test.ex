defmodule ExCraft.Car do
  require ExCraft
  ExCraft.craft [
    %ExCraft.Field{name: :brand,  type: :string,        required: false,   default: "custom",  enforce: false},
    %ExCraft.Field{name: :year,   type: :pos_integer,   required: true,    default: nil,       enforce: true},
    %ExCraft.Field{name: :used,   type: :boolean,       required: false,   default: true,      enforce: false},
  ]
end
