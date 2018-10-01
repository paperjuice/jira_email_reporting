defmodule MailReportTest do
  use ExUnit.Case
  doctest MailReport

  test "greets the world" do
    assert MailReport.hello() == :world
  end
end
