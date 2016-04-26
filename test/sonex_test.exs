defmodule SonexTest do
  use ExUnit.Case
  doctest Sonex

  setup do
    # wait for discovery before running tests
    IO.puts "Discovering..."
    :timer.sleep(100)
  end

  test "discovery" do
    {:ok, players }  = Sonex.Discovery.players()
    assert Enum.count(players) > 0
  end

  test "error messages - Invalid Action" do
    {:ok, players }  = Sonex.Discovery.players()
    a_player = List.first(players)
    {:error, err_msg} = Sonex.SOAP.build(:device, "badReq") |> Sonex.SOAP.post(a_player)
    assert err_msg == "Invalid Action"
  end

  test "error messages - Invalid Arg" do
    {:ok, players }  = Sonex.Discovery.players()
    a_player = List.first(players)
    {:error, err_msg} = Sonex.SOAP.build(:device, "SetLEDState", [["badArg", "Off"]]) |> Sonex.SOAP.post(a_player)
    assert err_msg == "Invalid Args"
  end

end
