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
    let messageHeading = document.createElement('h4');
    messageHeading.className = 'text-base font-bold underline';

    let messageTitle = document.createElement('a');
    messageTitle.href = `https://news.ycombinator.com/item?id=${story.id}`;
    messageTitle.textContent = `[#${story.id}] ${story.title}`;

    messageHeading.append(messageTitle);

    let messageByline = document.createElement('div');
    messageByline.className = 'text-sm font-normal';
    messageByline.textContent = `${story.score} points by ${story.by} | ${story.descendants} comments`;

    let messageCont = document.createElement('div');
    messageCont.className = 'container mx-auto py-2';

    messageCont.append(messageHeading);
    messageCont.append(messageByline);
    messageCont.append(document.createElement('hr'));

    container.append(messageCont);
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
