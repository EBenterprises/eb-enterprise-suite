document.getElementById('captureForm').addEventListener('submit', async function(e) {
  e.preventDefault();
  
  const name = document.getElementById('name').value;
  const email = document.getElementById('email').value;
  const msgBox = document.getElementById('messageBox');
  
  msgBox.className = 'message-box';
  msgBox.style.display = 'none';

  try {
    const response = await fetch('/api/capture', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ name, email })
    });

    const data = await response.json();

    if (data.success) {
      msgBox.className = 'message-box success';
      msgBox.textContent = data.message;
      document.getElementById('captureForm').reset();
    } else {
      msgBox.className = 'message-box error';
      msgBox.textContent = data.message;
    }
  } catch (err) {
    msgBox.className = 'message-box error';
    msgBox.textContent = 'Connection error. Please try again.';
  }
});
