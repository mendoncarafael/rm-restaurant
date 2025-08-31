$(document).ready(function () {
  // Variables
  let restaurants = [];
  let playerJob = '';
  let playerGrade = '';
  let currentFilter = 'all';

  // Initialize time display
  updateTime();
  setInterval(updateTime, 1000);

  // Initialize tablet
  initializeTablet();

  // Listener for messages from the game client
  window.addEventListener('message', function (event) {
    const data = event.data;

    if (data.action === 'openMenu') {
      restaurants = data.restaurants;
      playerJob = data.job;
      playerGrade = data.grade;
      openTabletMenu();
      updateRestaurantsDisplay();
    } else if (data.action === 'showRestaurantNotification') {
      // Show restaurant notification to all players
      showRestaurantStatusNotificationFromServer(data);
    }
  });

  // Initialize tablet interface
  function initializeTablet() {
    // Add event listeners for navigation
    $('.nav-btn').on('click', function () {
      const page = $(this).data('page');
      if (page) {
        switchPage(page);
      }
    });

    // Close button
    $('#close-app').on('click', function () {
      closeTabletMenu();
    });

    // Filter buttons
    $('.filter-btn').on('click', function () {
      const filter = $(this).data('filter');
      setFilter(filter);
    });

    // Header buttons
    $('#notifications-btn, #settings-btn').on('click', function () {
      // Add notification/settings functionality here
      console.log('Button clicked:', this.id);
    });
  }

  // Update time display
  function updateTime() {
    const now = new Date();
    const time = now.toLocaleTimeString('pt-BR', {
      hour: '2-digit',
      minute: '2-digit',
      hour12: false,
    });
    $('#current-time').text(time);
  }

  // Open the tablet menu with animation
  function openTabletMenu() {
    $('#tablet-device').removeClass('tablet-off').addClass('tablet-on');
  }

  // Close the tablet menu with animation
  function closeTabletMenu() {
    $('#tablet-device').removeClass('tablet-on').addClass('tablet-off');
    setTimeout(() => {
      $.post('https://rm-restaurant/closeMenu');
    }, 300);
  }

  // Switch navigation pages
  function switchPage(page) {
    $('.nav-btn').removeClass('active');
    $(`.nav-btn[data-page="${page}"]`).addClass('active');

    // Handle page switching logic here
    console.log('Switching to page:', page);
  }

  // Set active filter
  function setFilter(filter) {
    currentFilter = filter;
    $('.filter-btn').removeClass('active');
    $(`.filter-btn[data-filter="${filter}"]`).addClass('active');

    // Filter restaurants
    filterRestaurants();
  }

  // Filter restaurants based on current filter
  function filterRestaurants() {
    $('.restaurant-card').each(function () {
      const category = $(this).data('category');
      const shouldShow =
        currentFilter === 'all' ||
        (currentFilter === 'food' && category === 'food') ||
        (currentFilter === 'drinks' && category === 'drinks');

      if (shouldShow) {
        $(this).removeClass('hidden').css('animation-delay', '');
      } else {
        $(this).addClass('hidden');
      }
    });
  }

  // Update the restaurants display in the menu
  function updateRestaurantsDisplay() {
    console.log('Updating restaurants display:', restaurants);

    if (!restaurants || restaurants.length === 0) {
      console.error('No restaurant data available');
      $('#restaurants-grid .restaurants-container').html(
        '<div class="no-restaurants" style="grid-column: 1/-1; text-align: center; padding: 2rem; color: var(--text-secondary);">Nenhum restaurante disponível</div>'
      );
      return;
    }

    // Clear previous content
    $('#active-restaurant').empty();
    $('#restaurants-grid .restaurants-container').empty();

    // Display active restaurant (employee restaurant or first one)
    const activeRestaurant =
      restaurants.find((r) => r.isEmployee) || restaurants[0];
    if (activeRestaurant) {
      displayActiveRestaurant(activeRestaurant);
    }

    // Display all restaurants in grid
    restaurants.forEach((restaurant, index) => {
      displayRestaurantCard(restaurant, index);
    });

    // Apply current filter
    filterRestaurants();
  }

  // Display the active/featured restaurant
  function displayActiveRestaurant(restaurant) {
    const template = document.getElementById('active-restaurant-template');
    if (!template) {
      console.error('Active restaurant template not found');
      return;
    }

    // Clear existing content first
    $('#active-restaurant').empty();

    const clone = template.content.cloneNode(true);

    // Set restaurant info
    const titleElement = clone.querySelector('.restaurant-title');
    if (titleElement) {
      titleElement.textContent = restaurant.label || restaurant.name;
    }

    // Set restaurant images
    const bgImg = clone.querySelector('.restaurant-bg-img');
    const logo = clone.querySelector('.restaurant-logo');
    const restaurantImage = getRestaurantImage(restaurant.name);

    if (bgImg) {
      bgImg.src = restaurantImage;
      bgImg.alt = restaurant.label || restaurant.name;
    }
    if (logo) {
      logo.src = restaurantImage;
      logo.alt = restaurant.label || restaurant.name;
    }

    // Set status
    const statusLight = clone.querySelector('.status-light');
    const statusText = clone.querySelector('.status-text');
    if (statusLight && statusText) {
      if (restaurant.status) {
        statusLight.classList.remove('closed');
        statusText.textContent = 'ABERTO';
      } else {
        statusLight.classList.add('closed');
        statusText.textContent = 'FECHADO';
      }
    }

    // Set up toggle button
    const toggleBtn = clone.querySelector('.toggle-btn');
    if (toggleBtn && restaurant.isEmployee) {
      toggleBtn.addEventListener('click', function () {
        toggleRestaurant(restaurant.id, !restaurant.status);

        // Visual feedback
        this.style.transform = 'scale(0.95)';
        setTimeout(() => {
          this.style.transform = '';
        }, 150);
      });
    } else if (toggleBtn) {
      toggleBtn.style.opacity = '0.5';
      toggleBtn.style.cursor = 'not-allowed';
    }

    // Set up location button
    const locationBtn = clone.querySelector('.location-btn');
    if (locationBtn) {
      locationBtn.addEventListener('click', function () {
        setWaypoint(restaurant.id);

        // Visual feedback
        this.style.transform = 'translateY(-2px)';
        setTimeout(() => {
          this.style.transform = '';
        }, 200);
      });
    }

    $('#active-restaurant').append(clone);
  }

  // Display restaurant card in grid
  function displayRestaurantCard(restaurant, index) {
    const template = document.getElementById('restaurant-card-template');
    if (!template) {
      console.error('Restaurant card template not found');
      return;
    }

    const clone = template.content.cloneNode(true);
    const card = clone.querySelector('.restaurant-card');

    // Set category for filtering
    const category = categorizeRestaurant(restaurant.name);
    card.dataset.category = category;
    card.dataset.id = restaurant.id;

    // Set animation delay for staggered entrance
    card.style.animationDelay = `${index * 0.1}s`;

    // Set restaurant name
    const nameElement = clone.querySelector('.restaurant-name');
    if (nameElement) {
      nameElement.textContent = restaurant.label || restaurant.name;

      // Add manager crown if applicable
      if (restaurant.isManager) {
        const crown = document.createElement('i');
        crown.className = 'fas fa-crown';
        crown.style.color = '#fbbf24';
        crown.style.marginLeft = '8px';
        crown.title = 'Você tem permissões de gerente';
        nameElement.appendChild(crown);
      }
    }

    // Set restaurant image
    const thumbImg = clone.querySelector('.thumb-img');
    if (thumbImg) {
      thumbImg.src = getRestaurantImage(restaurant.name);
      thumbImg.alt = restaurant.label || restaurant.name;
      thumbImg.onerror = function () {
        this.src = 'img/burger.png'; // Fallback image
      };
    }

    // Set status badge
    const statusDot = clone.querySelector('.status-dot');
    if (statusDot) {
      if (!restaurant.status) {
        statusDot.classList.add('closed');
      }
    }

    // Set up action buttons
    const locationBtn = clone.querySelector('.location-btn');
    if (locationBtn) {
      locationBtn.addEventListener('click', function (e) {
        e.stopPropagation();
        setWaypoint(restaurant.id);
      });
    }

    const managerBtn = clone.querySelector('.manager-btn');
    if (managerBtn && restaurant.isManager) {
      managerBtn.style.display = 'flex';
      managerBtn.addEventListener('click', function (e) {
        e.stopPropagation();
        accessManagement(restaurant.id);
      });
    }

    // Add click handler for the whole card
    card.addEventListener('click', function () {
      console.log(
        `Card clicked for restaurant: ${restaurant.name}, ID: ${restaurant.id}, isEmployee: ${restaurant.isEmployee}, current status: ${restaurant.status}`
      );

      // Only display the restaurant - no status toggling from cards
      console.log(
        `Restaurant card clicked, displaying restaurant details only`
      );

      // Always update the active restaurant display
      displayActiveRestaurant(restaurant);

      // Scroll to top smoothly
      $('.main-content').animate({ scrollTop: 0 }, 300);
    });

    // Set cursor to pointer for all cards since they're clickable for viewing
    card.style.cursor = 'pointer';

    $('#restaurants-grid .restaurants-container').append(clone);
  }

  // Categorize restaurant for filtering
  function categorizeRestaurant(name) {
    const lowerName = name.toLowerCase();

    if (
      lowerName.includes('burger') ||
      lowerName.includes('siri') ||
      lowerName.includes('venetian') ||
      lowerName.includes('greasy') ||
      lowerName.includes('uwu') ||
      lowerName.includes('cafe')
    ) {
      return 'food';
    } else if (
      lowerName.includes('bahama') ||
      lowerName.includes('tequi') ||
      lowerName.includes('bar')
    ) {
      return 'drinks';
    }
    return 'other';
  }

  // Get restaurant image based on name
  function getRestaurantImage(name) {
    const lowerName = name.toLowerCase();

    if (lowerName.includes('burger')) {
      return 'img/burger.png';
    } else if (lowerName.includes('siri')) {
      return 'img/siri.png';
    } else if (lowerName.includes('venetian')) {
      return 'img/venetian.png';
    } else if (lowerName.includes('greasy')) {
      return 'img/greasy.png';
    } else if (lowerName.includes('uwu')) {
      return 'img/uwu.png';
    } else if (lowerName.includes('bahama')) {
      return 'img/bahama.png';
    } else if (lowerName.includes('tequi')) {
      return 'img/tequilala.png';
    } else if (lowerName.includes('cafe')) {
      return 'img/cafe.png';
    }

    return 'img/burger.png'; // Default fallback
  }

  // Show restaurant status notification received from server
  function showRestaurantStatusNotificationFromServer(data) {
    const statusColor = data.isOpen
      ? 'var(--success-color)'
      : 'var(--error-color)';
    const iconClass = data.isOpen ? 'fa-check-circle' : 'fa-times-circle';

    // Calculate position based on existing notifications
    const existingNotifications = $('.restaurant-notification-global').length;
    const topPosition = 20 + existingNotifications * 100; // Stack notifications 140px apart for better spacing

    const notification = $(`
            <div class="restaurant-notification-global" style="
                position: fixed;
                top: ${topPosition}px;
                right: 20px;
                background: rgba(255, 255, 255, 0.95);
                border: 1px solid rgba(255, 255, 255, 0.3);
                border-radius: var(--radius-xl);
                padding: 12px;
                color: var(--text-primary);
                box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
                z-index: ${10000 + existingNotifications};
                min-width: 300px;
                max-width: 400px;
                transform: translateX(100%);
                transition: all 0.4s ease;
                margin-bottom: var(--spacing-md);
            ">
                <div style="display: flex; align-items: center; gap: var(--spacing-md);">
                    <div style="
                        width: 60px;
                        height: 60px;
                        border-radius: var(--radius-xl);
                        overflow: hidden;
                        background: var(--bg-primary);
                        padding: 4px;
                        box-shadow: var(--shadow-card);
                        flex-shrink: 0;
                    ">
                        <img src="${data.restaurantImage}" alt="${
      data.restaurantName
    }" style="
                            width: 100%;
                            height: 100%;
                            object-fit: cover;
                            border-radius: var(--radius-lg);
                        " onerror="this.src='img/burger.png'">
                    </div>
                    <div style="flex: 1; min-width: 0;">
                        <div style="
                            display: flex;
                            align-items: center;
                            gap: var(--spacing-sm);
                            margin-bottom: var(--spacing-xs);
                        ">
                            <i class="fas ${iconClass}" style="color: ${statusColor}; font-size: var(--font-size-lg);"></i>
                            <span style="
                                background: ${statusColor};
                                color: white;
                                padding: 2px 8px;
                                border-radius: var(--radius-sm);
                                font-size: var(--font-size-xs);
                                font-weight: 600;
                                letter-spacing: 0.5px;
                            ">${data.statusText}</span>
                        </div>
                        <h4 style="
                            font-size: var(--font-size-lg);
                            font-weight: 600;
                            color: var(--text-primary);
                            margin-bottom: var(--spacing-xs);
                            white-space: nowrap;
                            overflow: hidden;
                            text-overflow: ellipsis;
                        ">${data.restaurantName}</h4>
                        <p style="
                            font-size: var(--font-size-sm);
                            color: var(--text-secondary);
                            margin: 0;
                        ">${data.message}</p>
                    </div>
                </div>
            </div>
        `);

    $('body').append(notification);

    // Animate in
    setTimeout(() => {
      notification.css('transform', 'translateX(0)');
    }, 100);

    // Animate out and remove, then reposition remaining notifications
    setTimeout(() => {
      notification.css('transform', 'translateX(100%)');
      setTimeout(() => {
        notification.remove();
        // Reposition remaining notifications
        repositionNotifications();
      }, 400);
    }, 6000); // Show for 6 seconds for global notifications
  }

  // Reposition notifications after one is removed
  function repositionNotifications() {
    $('.restaurant-notification-global').each(function (index) {
      const newTop = 20 + index * 140; // Match the 140px spacing
      $(this).css({
        top: newTop + 'px',
        transition: 'all 0.3s ease',
      });
    });
  }

  // Show restaurant status notification to all players
  function showRestaurantStatusNotification(restaurant, isOpen) {
    // Don't show local notification - only send to server for global broadcast
    // This prevents double notifications for the person who triggered the change

    // Send notification to all players via the game client
    $.post(
      'https://rm-restaurant/notifyAllPlayers',
      JSON.stringify({
        restaurantId: restaurant.id,
        restaurantName: restaurant.label || restaurant.name,
        restaurantImage: getRestaurantImage(restaurant.name),
        isOpen: isOpen,
        message: isOpen
          ? 'Está agora aberto para pedidos!'
          : 'foi fechado temporariamente.',
      })
    );
  }

  // Toggle restaurant status
  function toggleRestaurant(id, state) {
    console.log(`Toggling restaurant ${id} to ${state ? 'open' : 'closed'}`);

    // Find the restaurant by ID
    const restaurant = restaurants.find((r) => r.id === id);
    if (!restaurant) {
      console.error(`Restaurant with ID ${id} not found`);
      return;
    }

    console.log(
      `Found restaurant: ${restaurant.name}, current status: ${restaurant.status}, employee: ${restaurant.isEmployee}`
    );

    // Send to game client
    $.post(
      'https://rm-restaurant/toggleRestaurant',
      JSON.stringify({
        id: id,
        state: state,
      })
    );

    // Update local state
    restaurant.status = state;

    // Update UI elements
    updateRestaurantStatus(id, state);

    // Show notification to all players
    showRestaurantStatusNotification(restaurant, state);
  }

  // Update restaurant status in UI
  function updateRestaurantStatus(id, isOpen) {
    // Update in active restaurant card
    const activeCard = $('#active-restaurant');
    const statusLight = activeCard.find('.status-light');
    const statusText = activeCard.find('.status-text');

    if (statusLight.length && statusText.length) {
      if (isOpen) {
        statusLight.removeClass('closed');
        statusText.text('ABERTO');
      } else {
        statusLight.addClass('closed');
        statusText.text('FECHADO');
      }
    }

    // Update in restaurant cards (only status dots now)
    $(`.restaurant-card[data-id="${id}"]`).each(function () {
      const statusDot = $(this).find('.status-dot');

      if (isOpen) {
        statusDot.removeClass('closed');
      } else {
        statusDot.addClass('closed');
      }
    });
  }

  // Access restaurant management
  function accessManagement(id) {
    console.log(`Accessing management for restaurant ${id}`);

    $.post(
      'https://rm-restaurant/accessManagement',
      JSON.stringify({
        id: id,
      })
    );
  }

  // Set waypoint to restaurant
  function setWaypoint(restaurantId) {
    console.log(`Setting waypoint for restaurant ${restaurantId}`);

    $.post(
      'https://rm-restaurant/setWaypoint',
      JSON.stringify({
        id: restaurantId,
      })
    );

    // Show notification
    showNotification('GPS definido para o restaurante!', 'success');
  }

  // Show notification
  function showNotification(message, type = 'info', duration = 3000) {
    const notification = $(`
            <div class="notification notification-${type}" style="
                position: fixed;
                top: 20px;
                right: 20px;
                background: var(--bg-glass);
           
                border: 1px solid var(--border-light);
                border-radius: var(--radius-lg);
                padding: var(--spacing-md) var(--spacing-lg);
                color: var(--text-primary);
                box-shadow: var(--shadow-card);
                z-index: 9999;
                transform: translateX(100%);
                transition: transform 0.3s ease;
            ">
                <i class="fas fa-${
                  type === 'success' ? 'check-circle' : 'info-circle'
                }" style="margin-right: 8px; color: var(--${
      type === 'success' ? 'success' : 'primary'
    }-color);"></i>
                ${message}
            </div>
        `);

    $('body').append(notification);

    // Animate in
    setTimeout(() => {
      notification.css('transform', 'translateX(0)');
    }, 100);

    // Animate out and remove
    setTimeout(() => {
      notification.css('transform', 'translateX(100%)');
      setTimeout(() => {
        notification.remove();
      }, 300);
    }, duration);
  }

  // Handle escape key to close menu
  $(document).keydown(function (e) {
    if (e.keyCode === 27) {
      // ESC key
      closeTabletMenu();
    }
  });

  // Prevent context menu on tablet
  $('#tablet-device').on('contextmenu', function (e) {
    e.preventDefault();
  });

  // Add smooth scrolling to main content
  $('.main-content').on('scroll', function () {
    const scrollTop = $(this).scrollTop();
    const header = $('.app-header');

    if (scrollTop > 50) {
      header.css('backdrop-filter', 'blur(0px)');
    } else {
      header.css('backdrop-filter', 'blur(0px)');
    }
  });
});
