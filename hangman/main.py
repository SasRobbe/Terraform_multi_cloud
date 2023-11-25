from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import random
import requests
from fastapi.middleware.cors import CORSMiddleware

# Create a FastAPI app
app = FastAPI()

# Define a list of allowed origins
origins = ["*"]

# Add the CORSMiddleware as a middleware to your app
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Define a pydantic model for the game state
class HangmanIn(BaseModel):
    word: str
    guessed: str
    attempts: int
    output: str


class HangmanOut(BaseModel):
    guessed: str
    attempts: int
    output: str


# Define a global variable to store the current game
game = None


# Define a helper function to get a random word from Words API
def get_random_word() -> str:
    # Set the base URL for Words API
    base_url = "https://random-word-api.herokuapp.com/word"
    # Set the headers for authentication
    # headers = {
    #     "x-rapidapi-key": "YOUR_API_KEY",  # Replace with your own API key
    #     "x-rapidapi-host": "wordsapiv1.p.rapidapi.com",
    # }
    # Set the query parameters for frequency and category
    # params = {
    #     "frequencyMin": 4,
    #     "frequencyMax": 8,
    #     "random": True,
    #     "letterPattern": "^[a-z]+$",  # Only allow lowercase letters
    # }
    # Make a GET request to Words API and get the response as JSON
    # response = requests.get(base_url + language, headers=headers, params=params).json()
    response = requests.get(base_url).json()
    # Return the word from the response or raise an exception if not found
    return response[0]


# Define an endpoint for starting a new game
@app.post("/hangman/new", response_model=HangmanOut)
def new_game(max_attempts: int = 6):
    global game  # Use the global game variable
    # Get a random word from Words API
    word = get_random_word()
    # Initialize the game state with the word, empty guessed letters, and max attempts and output (_ times the length of the word)
    game = HangmanIn(
        word=word, guessed="", attempts=max_attempts, output="_ " * len(word)
    )
    # Return the game state as JSON
    return game


# Define an endpoint for making a guess
@app.post("/hangman/guess/{letter}", response_model=HangmanOut)
def guess_game(letter: str):
    global game  # Use the global game variable
    # Check if there is an active game or raise an exception
    if not game:
        raise HTTPException(status_code=400, detail="No active game")
    # Check if the letter is valid or raise an exception
    if not letter.isalpha() or len(letter) != 1:
        raise HTTPException(status_code=400, detail="Invalid letter")
    # Check if the letter has already been guessed or raise an exception
    if letter in game.guessed:
        raise HTTPException(status_code=400, detail="Letter already guessed")
    # Add the letter to the guessed letters
    game.guessed += letter.lower()
    # Check if the letter is in the word or reduce the attempts by one
    if letter.lower() not in game.word.lower():
        game.attempts -= 1
    else:
        # reset output
        game.output = ""
        # Loop through each character in the word
        for char in game.word:
            # If the character is in the guessed letters or is not a letter, add it to the output
            if char.lower() in game.guessed or not char.isalpha():
                game.output = game.output + char + " "
            else:
                # Otherwise, add an underscore to the output
                game.output = game.output + "_ "
    # Return the game state as JSON
    return game


# Define an endpoint for showing the remaining attempts
@app.get("/hangman/attempts")
def attempts_game():
    global game  # Use the global game variable
    # Check if there is an active game or raise an exception
    if not game:
        raise HTTPException(status_code=400, detail="No active game")
    # Return the remaining attempts as JSON
    return {"attempts": game.attempts}


# Define an endpoint to show the solution word
@app.get("/hangman/solution")
def solution_game():
    global game
    if not game:
        raise HTTPException(status_code=400, detail="No active game")
    return {"solution": game.word}


# Add liveness endpoint that returns 200
@app.get("/liveness")
def liveness():
    return {"status": "ok"}
