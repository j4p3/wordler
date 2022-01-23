defmodule Wordler.Puzzle do
  @moduledoc """
  Functions for solving Wordler puzzles.
  """
  @default_source Wordler.Sources.Dict

  @type t() :: %__MODULE__{
          word_list: [binary()],
          solution_list: [binary()],
          guesses: [binary()],
          guessed_letters: MapSet.t(integer()),
          rejected_letters: MapSet.t(integer()),
          solution_members: MapSet.t(integer()),
          solution_positions: [nil | integer()],
          solution_antipositions: [MapSet.t(integer())],
          solution: binary()
        }

  defstruct word_list: [],
            solution_list: [],
            guesses: [],
            guessed_letters: MapSet.new(),
            rejected_letters: MapSet.new(),
            solution_members: MapSet.new(),
            solution_positions: [nil, nil, nil, nil, nil],
            solution_antipositions: [
              MapSet.new(),
              MapSet.new(),
              MapSet.new(),
              MapSet.new(),
              MapSet.new()
            ],
            solution: nil

  @doc """
  Creates a new blank puzzle.

  ## Examples

      iex> Wordler.Puzzle.new()
      %Wordler.Puzzle{word_list: [], ...}
  """
  def new(options \\ []) do
    source_module = Keyword.get(options, :source, @default_source)

    word_list =
      apply(source_module, :five_letter_words, [])
      |> Enum.sort(fn word1, word2 ->
        Wordler.Sources.WordBank.frequency_score(word1) >
          Wordler.Sources.WordBank.frequency_score(word2)
      end)

    solution_list =
      apply(source_module, :five_letter_words, [[{:duplicates, true}]])
      |> Enum.sort(fn word1, word2 ->
        Wordler.Sources.WordBank.frequency_score(word1) >
          Wordler.Sources.WordBank.frequency_score(word2)
      end)

    %__MODULE__{
      word_list: word_list,
      solution_list: solution_list
    }
  end

  @doc """
  Generate the next guess for a given puzzle.

  Returns a binary string guess. Will return an "exploratory guess" if possible,
  covering new unguessed letters, or fall back to a "solving guess" if no exploratory guesses are possible.

  ## Examples

      iex> Wordler.Puzzle.new()
      |> Wordler.Puzzle.new_guess()
      "irate"
  """
  @spec next_guess(t()) :: binary()
  def next_guess(puzzle) do
    # @todo do something proportionate with solving vs exploratory guesses:
    # potential % reduction of solution list vs confidence of solve
    case exploratory_guesses(puzzle) do
      [] -> List.first(solving_guesses(puzzle))
      guesses -> List.first(guesses)
    end
  end

  @doc """
  Handle the results of a guess.

  Returns a new Puzzle with updated constraints and reduced word counts.

  ## Examples

      iex> puzzle = Wordler.Puzzle.new()
      %Wordler.Puzzle{word_list: [], ...}
      iex> length(puzzle.solution_list)
      4594
      iex> guess = Wordler.Puzzle.new_guess(puzzle)
      "irate"
      iex> results = [true, "r", false, false, false]
      [true, "r", false, false, false]
      iex> puzzle = Wordler.Puzzle.handle_guess(puzzle, guess, results)
      %Wordler.Puzzle{word_list: [], ...}
      iex> length(puzzle.solution_list)
      95
  """
  @spec handle_guess(t(), binary(), [true | false | binary()]) :: Wordler.Puzzle.t()
  def handle_guess(puzzle, guess, letter_results) do
    {updated_puzzle, _} =
      Enum.zip(String.to_charlist(guess), letter_results)
      |> Enum.reduce({puzzle, 0}, fn {letter, result}, {puzzle_acc, i} ->
        case result do
          result when is_binary(result) ->
            {add_position(puzzle_acc, letter, i), i + 1}

          true ->
            {
              puzzle_acc
              |> add_member(letter)
              |> add_antiposition(letter, i),
              i + 1
            }

          false ->
            {add_reject(puzzle_acc, letter), i + 1}
        end
      end)

    updated_puzzle
    |> add_guess(guess)
    |> update_search_space()
  end

  defp exploratory_guesses(puzzle) do
    # guesses having as little in common as possible with known solution members as possible
    puzzle.word_list
    |> Enum.reject(fn word ->
      for(<<char <- word>>, do: char in puzzle.solution_members)
      |> Enum.any?()
    end)
  end

  defp solving_guesses(puzzle) do
    # guesses having as much in common with solution_members as possible
    puzzle.solution_list
    |> Enum.map(fn word ->
      common_members =
        for <<char <- word>>, reduce: 0 do
          acc ->
            cond do
              char in puzzle.solution_members -> acc + 1
              true -> acc
            end
        end

      {word, common_members}
    end)
    |> Enum.sort(fn {w1, cm1}, {w2, cm2} ->
      if cm1 > cm2 do
        true
      else
        Wordler.Sources.WordBank.frequency_score(w1) >
          Wordler.Sources.WordBank.frequency_score(w2)
      end
    end)
    |> Enum.map(&elem(&1, 0))
  end

  defp update_search_space(%__MODULE__{} = puzzle) do
    %__MODULE__{
      puzzle
      | word_list: filter_list(puzzle, :word_list),
        solution_list: filter_list(puzzle, :solution_list)
    }
  end

  defp filter_list(puzzle, list_type) do
    Map.get(puzzle, list_type)
    |> Enum.filter(fn word ->
      Enum.zip([
        String.to_charlist(word),
        puzzle.solution_positions,
        puzzle.solution_antipositions
      ])
      |> Enum.reduce_while(true, fn {char, at_position, not_at_position}, _ ->
        cond do
          list_type != :word_list && at_position && at_position != char ->
            IO.puts(
              "rejecting #{word} due to position of #{<<char>>} conflicting with known #{<<at_position>>} at that position"
            )

            {:halt, false}

          char in not_at_position ->
            IO.puts(
              "rejecting #{word} due to position of #{<<char>>} known not to be at that position"
            )

            {:halt, false}

          char in puzzle.rejected_letters ->
            IO.puts("rejecting #{word} due presence of #{<<char>>}")
            {:halt, false}

          true ->
            {:cont, true}
        end
      end)
    end)
  end

  defp add_guess(%__MODULE__{guesses: guesses, guessed_letters: guessed_letters} = puzzle, guess) do
    new_guesses = Enum.reverse([guess | Enum.reverse(guesses)])

    new_guessed_letters =
      guess
      |> String.to_charlist()
      |> Enum.reduce(guessed_letters, fn char, guessed -> MapSet.put(guessed, char) end)

    %__MODULE__{puzzle | guesses: new_guesses, guessed_letters: new_guessed_letters}
  end

  defp add_reject(%__MODULE__{rejected_letters: rejected_letters} = puzzle, rejected_letter) do
    IO.puts("rejecting #{<<rejected_letter>>}")

    %__MODULE__{
      puzzle
      | rejected_letters: MapSet.put(rejected_letters, rejected_letter)
    }
  end

  defp add_member(%__MODULE__{solution_members: solution_members} = puzzle, member_letter) do
    IO.puts("adding #{<<member_letter>>}")

    %__MODULE__{
      puzzle
      | solution_members: MapSet.put(solution_members, member_letter)
    }
  end

  defp add_position(
         %__MODULE__{solution_positions: solution_positions} = puzzle,
         member_letter,
         member_position
       ) do
    IO.puts("adding #{<<member_letter>>} at position #{member_position}")

    %__MODULE__{
      puzzle
      | solution_positions: List.replace_at(solution_positions, member_position, member_letter)
    }
    |> add_member(member_letter)
  end

  defp add_antiposition(
         %__MODULE__{solution_antipositions: solution_antipositions} = puzzle,
         member_letter,
         member_antiposition
       ) do
    IO.puts("adding #{<<member_letter>>} in antiposition #{member_antiposition}")

    %__MODULE__{
      puzzle
      | solution_antipositions:
          List.update_at(solution_antipositions, member_antiposition, fn ex ->
            MapSet.put(ex, member_letter)
          end)
    }
    |> add_member(member_letter)
  end
end
