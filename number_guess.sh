#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -q -c"

printf "Enter your username:\n"
read -r username
username_sql=${username//\'/\'\'}

user_id=$($PSQL "SELECT user_id FROM users WHERE username='$username_sql'")
if [[ -z $user_id ]]; then
  user_id=$($PSQL "INSERT INTO users(username) VALUES ('$username_sql') RETURNING user_id")
  printf "Welcome, %s! It looks like this is your first time here.\n" "$username"
else
  IFS='|' read -r games_played best_game <<< "$($PSQL "SELECT COUNT(*), MIN(number_guesses) FROM games WHERE user_id=$user_id")"
  printf "Welcome back, %s! You have played %s games, and your best game took %s guesses.\n" "$username" "$games_played" "$best_game"
fi

secret_number=$(( RANDOM % 1000 + 1 ))
number_of_guesses=0

printf "Guess the secret number between 1 and 1000:\n"
while read -r guess; do
  if [[ ! $guess =~ ^[+-]?[0-9]+$ ]]; then
    printf "That is not an integer, guess again:\n"
    continue
  fi

  if [[ $guess == -* ]]; then
    guess_number=$((-10#${guess#-}))
  else
    guess_number=$((10#${guess#+}))
  fi

  number_of_guesses=$((number_of_guesses + 1))
  if (( guess_number == secret_number )); then
    $PSQL "INSERT INTO games(user_id, number_guesses) VALUES ($user_id, $number_of_guesses)" > /dev/null
    printf "You guessed it in %s tries. The secret number was %s. Nice job!\n" "$number_of_guesses" "$secret_number"
    break
  elif (( guess_number > secret_number )); then
    printf "It's lower than that, guess again:\n"
  else
    printf "It's higher than that, guess again:\n"
  fi
done
