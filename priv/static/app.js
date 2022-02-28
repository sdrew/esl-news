function renderEmptyState() {
  const container = document.getElementById('messages');
  container.innerHTML = '';

  let messageElem = document.createElement('div');
  messageElem.className = 'container mx-auto';
  messageElem.textContent = 'No stories currently available';

  container.prepend(messageElem);
}

function renderStories(stories) {
  const container = document.getElementById('messages');
  container.innerHTML = '';

  stories.forEach(story => {
    let messageElem = document.createElement('div');
    messageElem.className = 'container mx-auto';
    messageElem.textContent = story.title;

    container.append(messageElem);
  });
}

function setupWS(ws_uri) {
  let socket = new WebSocket(ws_uri);

  socket.onopen = function (e) {
    console.log('[ws open]');
  };

  socket.onmessage = function (e) {
    console.log(`[ws data] ${e.data}`);

    setTimeout(() => socket.send('ping'), 10000);

    const stories = JSON.parse(e.data);
    if (stories.length > 0) {
      renderStories(stories);
    } else {
      renderEmptyState();
    }
  };

  socket.onclose = function (e) {
    console.log('[ws close]');
    // socket.close(1000, "Work complete");
  };

  return socket;
}

const ws_uri = document.location.href.replace(/https?/, 'ws') + 'api/ws';
const eslnews = setupWS(ws_uri);
