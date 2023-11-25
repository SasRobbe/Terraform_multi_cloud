window.onload = function () {
    // Get the HTML elements by their IDs
    const output = document.getElementById("output");
    const attempts = document.getElementById("attempts");
    const letter = document.getElementById("letter");
    const submit = document.getElementById("submit");
    const solution = document.getElementById("solution");

    // Define a variable to store the base URL of your API
    const baseURL = "https://${api_host}"; // Replace with your own API URL

    // Define a function to start a new game
    function newGame() {
        // Make a POST request to the /hangman/new endpoint with the max attempts parameter
        fetch(baseURL + "/hangman/new", {
            method: "POST"
        })
            .then(response => response.json()) // Parse the response as JSON
            .then(data => {
                // Update the output and attempts elements with the data from the response
                output.textContent = data.output;
                attempts.textContent = "Attempts left: " + data.attempts;
            })
            .catch(error => {
                // Handle any errors
                console.error(error);
                alert("Something went wrong. Please try again.");
            });
    }

    // Define a function to make a guess
    function guessGame() {
        // Get the value of the letter input field
        const guess = letter.value;
        // Check if the guess is valid
        if (guess.length === 1 && guess.match(/[a-z]/i)) {
            // Make a POST request to the /hangman/guess/{letter} endpoint with the guess parameter
            fetch(baseURL + "/hangman/guess/" + guess, {
                method: "POST"
            })
                .then(response => response.json()) // Parse the response as JSON
                .then(data => {
                    // Update the output and attempts elements with the data from the response
                    output.textContent = data.output;
                    attempts.textContent = "Attempts left: " + data.attempts;
                    // Check if the game is over or not
                    if (data.output.includes("_")) {
                        // If not, clear the letter input field and focus on it
                        letter.value = "";
                        letter.focus();
                    } else {
                        // If yes, disable the submit button and show a message
                        submit.disabled = true;
                        alert("You won! Congratulations!");
                    }
                })
                .catch(error => {
                    // Handle any errors
                    console.error(error);
                    alert("Something went wrong. Please try again.");
                });
        } else {
            // If not, show an error message and clear the letter input field
            alert("Invalid letter. Please enter a single letter from A to Z.");
            letter.value = "";
        }
    }

    // Define a function to show the solution
    function solutionGame() {
        // Make a GET request to the /hangman/solution endpoint
        fetch(baseURL + "/hangman/solution")
            .then(response => response.json()) // Parse the response as JSON
            .then(data => {
                // Update the output element with the data from the response
                output.textContent = data.solution;
                // Disable the submit and solution buttons and show a message
                submit.disabled = true;
                solution.disabled = true;
                alert("You gave up. Better luck next time.");
            })
            .catch(error => {
                // Handle any errors
                console.error(error);
                alert("Something went wrong. Please try again.");
            });
    }

    // Add event listeners to the buttons
    submit.addEventListener("click", guessGame); // Call the guessGame function when the submit button is clicked
    solution.addEventListener("click", solutionGame); // Call the solutionGame function when the solution button is clicked

    // Start a new game when the page loads
    newGame();
}
