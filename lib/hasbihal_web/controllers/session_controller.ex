defmodule HasbihalWeb.SessionController do
  use HasbihalWeb, :controller

  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]

  alias Hasbihal.Users
  alias Hasbihal.Users.User

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"session" => %{"email" => "", "password" => ""}}) do
    conn
    |> put_flash(:error, "Please fill in an email address and password")
    |> render("new.html")
  end

  def create(conn, %{"session" => %{"email" => email, "password" => password}}) do
    case verify_credentials(email, password) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Successfully signed in")
        |> Guardian.Plug.sign_in(user, %{some: "claim"}, ttl: {1, :minute})
        |> redirect(to: page_path(conn, :index))

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Invalid email address or password")
        |> render("new.html")
    end
  end

  def delete(conn, _params) do
    conn
    |> Guardian.Plug.sign_out()
    |> put_flash(:info, "Successfully signed out")
    |> redirect(to: "/")
  end

  defp verify_credentials(email, password) when is_binary(email) and is_binary(password) do
    with {:ok, user} <- find_by_email(email),
         do: verify_password(password, user)
  end

  defp find_by_email(email) when is_binary(email) do
    case Users.get_user_by_email!(email) do
      nil ->
        dummy_checkpw()
        {:error, "User with email '#{email}' not found"}

      user ->
        {:ok, user}
    end
  end

  defp verify_password(password, %User{} = user) when is_binary(password) do
    if checkpw(password, user.password_encrypted) do
      {:ok, user}
    else
      {:error, :invalid_password}
    end
  end
end
