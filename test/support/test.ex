defmodule ExCraft.Test do
  import ExCraft
  craft [
    %{name: :atom,           type: :atom,             required: true,  default: nil},
    %{name: :binary,         type: :binary,           required: false, default: "hello"},
    %{name: :string,         type: :string,           required: false, default: "world"},

    %{name: :number,         type: :number,           required: false, default: nil},
    %{name: :pos_number,     type: :pos_number,       required: false, default: nil},
    %{name: :non_neg_number, type: :non_neg_number,   required: false, default: nil},

    %{name: :integer,         type: :integer,         required: false, default: nil},
    %{name: :pos_integer,     type: :pos_integer,     required: false, default: nil},
    %{name: :non_neg_integer, type: :non_neg_integer, required: false, default: nil},

    %{name: :float,           type: :float,           required: false, default: nil},
    %{name: :pos_float,       type: :pos_float,       required: false, default: nil},
    %{name: :non_neg_float,   type: :non_neg_float,   required: false, default: nil},

    %{name: :struct,          type: :struct,          required: false, default: nil},
    %{name: :map,             type: :map,             required: false, default: nil},
    %{name: :list,            type: :list,            required: false, default: nil},
    %{name: :tuple,           type: :tuple,           required: false, default: nil},
    %{name: :keyword,         type: :keyword,         required: false, default: nil},
  ]
end
