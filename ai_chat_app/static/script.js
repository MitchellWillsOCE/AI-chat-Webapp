// Initialize timesContainer at the top of the script
const timesContainer = document.getElementById('generation-times');

document.getElementById('register-form').addEventListener('submit', async function (e) {
    e.preventDefault();
    const username = document.getElementById('register-username').value;
    const password = document.getElementById('register-password').value;
    const response = await fetch('api/register', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ username, password })
    });
    const result = await response.json();
    if (response.status === 200) {
        alert(result.message);
    } else {
        alert(result.detail);
    }
});

document.getElementById('login-form').addEventListener('submit', async function (e) {
    e.preventDefault();
    const username = document.getElementById('login-username').value;
    const password = document.getElementById('login-password').value;
    const response = await fetch('api/login', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ username, password })
    });
    const result = await response.json();
    if (response.status === 200) {
        sessionStorage.setItem('user_id', username);
        document.getElementById('login-form').style.display = 'none';
        document.getElementById('register-form').style.display = 'none';
        document.getElementById('chat').style.display = 'block';
        loadChatHistory();
    } else {
        alert(result.detail);
    }
});

document.getElementById('submit-button').addEventListener('click', async function() {
    const prompt = document.getElementById('prompt').value;
    const user_id = sessionStorage.getItem('user_id');

    // Show the progress bar and reset its width
    const progressBarContainer = document.getElementById('progress-bar-container');
    const progressBar = document.getElementById('progress-bar');
    progressBarContainer.style.display = 'block';
    progressBar.style.width = '0';

    try {
        // Start the timer
        const startTime = Date.now();

        // Simulate progress
        let progress = 0;
        const progressInterval = setInterval(() => {
            progress += 1;
            progressBar.style.width = progress + '%';

            if (progress >= 100) {
                clearInterval(progressInterval);
            }
        }, 100); // Update progress every 200ms

        // Send the request to the server
        const response = await fetch('api/generate', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ prompt, user_id })
        });

        // Calculate the time taken
        const endTime = Date.now();
        const timeTaken = endTime - startTime;

        // Send the generation time to the server for storage
        await fetch('api/store-time', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ timeTaken })
        });

        const result = await response.json();
        document.getElementById('response').textContent = result.response;
        loadChatHistory();

    } catch (error) {
        console.error('Error:', error);
    } finally {
        // Hide the progress bar after the request completes
        progressBarContainer.style.display = 'none';
    }
});

// Handle fetching and displaying generation times
document.getElementById('show-times-button').addEventListener('click', async function() {
    // Toggle visibility
    if (timesContainer.style.display === 'block') {
        // If visible, hide the container
        timesContainer.style.display = 'none';
    } else {
        // If hidden, show the container and fetch the times
        timesContainer.style.display = 'block';

        try {
            const response = await fetch('api/get-times');
            const data = await response.json();

            timesContainer.innerHTML = ''; // Clear previous content

            if (data.times.length === 0) {
                timesContainer.innerHTML = '<p>No generation times available.</p>';
            } else {
                data.times.forEach(time => {
                    const timeElement = document.createElement('p');
                    timeElement.textContent = `Time Taken: ${time} ms`;
                    timesContainer.appendChild(timeElement);
                });
            }
        } catch (error) {
            console.error('Error fetching generation times:', error);
        }
    }
});

async function loadChatHistory() {
    const user_id = sessionStorage.getItem('user_id');
    try {
        const response = await fetch(`api/chat_history/${user_id}`);
        const result = await response.json();
        const chatHistoryElement = document.getElementById('chat-history');
        chatHistoryElement.innerHTML = '';
        result.chat_history.forEach(entry => {
            const entryElement = document.createElement('div');
            entryElement.innerHTML = `<strong>Prompt:</strong> ${entry.prompt}<br><strong>Response:</strong> ${entry.response}<hr>`;
            chatHistoryElement.appendChild(entryElement);
        });
    } catch (error) {
        console.error('Error:', error);
    }
}

document.getElementById('clear-button').addEventListener('click', async function() {
    const user_id = sessionStorage.getItem('user_id');
    try {
        const response = await fetch(`api/clear_chat_history/${user_id}`, {
            method: 'DELETE'
        });
        if (response.status === 200) {
            loadChatHistory();
            document.getElementById('prompt').value = '';
            document.getElementById('response').textContent = '';
        } else {
            console.error('Error clearing chat history:', await response.text());
        }
    } catch (error) {
        console.error('Error:', error);
    }
});
