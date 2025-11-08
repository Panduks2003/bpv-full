/**
 * Service Worker for Advanced Caching and Performance Optimization
 * Handles asset caching, offline functionality, and CDN fallbacks
 */

const CACHE_NAME = 'brightplanet-v1.0.0';
const STATIC_CACHE = 'static-v1.0.0';
const DYNAMIC_CACHE = 'dynamic-v1.0.0';
const CDN_CACHE = 'cdn-v1.0.0';

// Assets to cache immediately
const STATIC_ASSETS = [
  '/',
  '/static/js/main.js',
  '/static/css/main.css',
  '/logo.png',
  '/favicon.ico',
  '/manifest.json'
];

// CDN domains to handle
const CDN_DOMAINS = [
  'cdn.brightplanetventures.com',
  'backup-cdn.brightplanetventures.com'
];

// Cache strategies
const CACHE_STRATEGIES = {
  CACHE_FIRST: 'cache-first',
  NETWORK_FIRST: 'network-first',
  STALE_WHILE_REVALIDATE: 'stale-while-revalidate',
  NETWORK_ONLY: 'network-only',
  CACHE_ONLY: 'cache-only'
};

// Route configurations
const ROUTE_CONFIG = [
  {
    pattern: /^https:\/\/.*\.(?:png|jpg|jpeg|svg|gif|webp|avif)$/,
    strategy: CACHE_STRATEGIES.CACHE_FIRST,
    cache: CDN_CACHE,
    maxAge: 30 * 24 * 60 * 60 * 1000, // 30 days
    maxEntries: 100
  },
  {
    pattern: /^https:\/\/.*\.(?:css|js)$/,
    strategy: CACHE_STRATEGIES.STALE_WHILE_REVALIDATE,
    cache: STATIC_CACHE,
    maxAge: 7 * 24 * 60 * 60 * 1000, // 7 days
    maxEntries: 50
  },
  {
    pattern: /\/api\//,
    strategy: CACHE_STRATEGIES.NETWORK_FIRST,
    cache: DYNAMIC_CACHE,
    maxAge: 5 * 60 * 1000, // 5 minutes
    maxEntries: 100
  },
  {
    pattern: /supabase\.co/,
    strategy: CACHE_STRATEGIES.NETWORK_FIRST,
    cache: DYNAMIC_CACHE,
    maxAge: 2 * 60 * 1000, // 2 minutes
    maxEntries: 200
  }
];

// Install event - cache static assets
self.addEventListener('install', (event) => {
  console.log('Service Worker: Installing...');
  
  event.waitUntil(
    Promise.all([
      caches.open(STATIC_CACHE).then((cache) => {
        console.log('Service Worker: Caching static assets');
        return cache.addAll(STATIC_ASSETS);
      }),
      self.skipWaiting()
    ])
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
  console.log('Service Worker: Activating...');
  
  event.waitUntil(
    Promise.all([
      // Clean up old caches
      caches.keys().then((cacheNames) => {
        return Promise.all(
          cacheNames.map((cacheName) => {
            if (cacheName !== STATIC_CACHE && 
                cacheName !== DYNAMIC_CACHE && 
                cacheName !== CDN_CACHE) {
              console.log('Service Worker: Deleting old cache:', cacheName);
              return caches.delete(cacheName);
            }
          })
        );
      }),
      self.clients.claim()
    ])
  );
});

// Fetch event - handle requests with caching strategies
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);
  
  // Skip non-GET requests
  if (request.method !== 'GET') {
    return;
  }
  
  // Skip chrome-extension and other non-http requests
  if (!request.url.startsWith('http')) {
    return;
  }

  // Find matching route configuration
  const routeConfig = ROUTE_CONFIG.find(config => 
    config.pattern.test(request.url)
  );

  if (routeConfig) {
    event.respondWith(
      handleRequest(request, routeConfig)
    );
  } else {
    // Default strategy for unmatched routes
    event.respondWith(
      handleRequest(request, {
        strategy: CACHE_STRATEGIES.NETWORK_FIRST,
        cache: DYNAMIC_CACHE,
        maxAge: 5 * 60 * 1000
      })
    );
  }
});

// Handle request based on strategy
async function handleRequest(request, config) {
  const { strategy, cache: cacheName, maxAge, maxEntries } = config;
  
  try {
    switch (strategy) {
      case CACHE_STRATEGIES.CACHE_FIRST:
        return await cacheFirst(request, cacheName, maxAge);
        
      case CACHE_STRATEGIES.NETWORK_FIRST:
        return await networkFirst(request, cacheName, maxAge);
        
      case CACHE_STRATEGIES.STALE_WHILE_REVALIDATE:
        return await staleWhileRevalidate(request, cacheName, maxAge);
        
      case CACHE_STRATEGIES.NETWORK_ONLY:
        return await fetch(request);
        
      case CACHE_STRATEGIES.CACHE_ONLY:
        return await cacheOnly(request, cacheName);
        
      default:
        return await networkFirst(request, cacheName, maxAge);
    }
  } catch (error) {
    console.error('Service Worker: Request handling failed:', error);
    return await handleFallback(request);
  }
}

// Cache First strategy
async function cacheFirst(request, cacheName, maxAge) {
  const cache = await caches.open(cacheName);
  const cachedResponse = await cache.match(request);
  
  if (cachedResponse && !isExpired(cachedResponse, maxAge)) {
    return cachedResponse;
  }
  
  try {
    const networkResponse = await fetch(request);
    
    if (networkResponse.ok) {
      // Clone response before caching
      const responseClone = networkResponse.clone();
      await cache.put(request, responseClone);
    }
    
    return networkResponse;
  } catch (error) {
    // Return cached response even if expired
    if (cachedResponse) {
      return cachedResponse;
    }
    throw error;
  }
}

// Network First strategy
async function networkFirst(request, cacheName, maxAge) {
  const cache = await caches.open(cacheName);
  
  try {
    const networkResponse = await fetch(request);
    
    if (networkResponse.ok) {
      // Clone response before caching
      const responseClone = networkResponse.clone();
      await cache.put(request, responseClone);
    }
    
    return networkResponse;
  } catch (error) {
    const cachedResponse = await cache.match(request);
    
    if (cachedResponse) {
      return cachedResponse;
    }
    
    throw error;
  }
}

// Stale While Revalidate strategy
async function staleWhileRevalidate(request, cacheName, maxAge) {
  const cache = await caches.open(cacheName);
  const cachedResponse = await cache.match(request);
  
  // Always try to fetch from network in background
  const networkPromise = fetch(request).then(async (networkResponse) => {
    if (networkResponse.ok) {
      const responseClone = networkResponse.clone();
      await cache.put(request, responseClone);
    }
    return networkResponse;
  }).catch(() => {
    // Ignore network errors in background
  });
  
  // Return cached response immediately if available
  if (cachedResponse) {
    // Don't await the network promise
    networkPromise;
    return cachedResponse;
  }
  
  // If no cached response, wait for network
  try {
    return await networkPromise;
  } catch (error) {
    throw error;
  }
}

// Cache Only strategy
async function cacheOnly(request, cacheName) {
  const cache = await caches.open(cacheName);
  const cachedResponse = await cache.match(request);
  
  if (cachedResponse) {
    return cachedResponse;
  }
  
  throw new Error('No cached response available');
}

// Check if cached response is expired
function isExpired(response, maxAge) {
  if (!maxAge) return false;
  
  const dateHeader = response.headers.get('date');
  if (!dateHeader) return false;
  
  const responseTime = new Date(dateHeader).getTime();
  const now = Date.now();
  
  return (now - responseTime) > maxAge;
}

// Handle fallback responses
async function handleFallback(request) {
  const url = new URL(request.url);
  
  // Return offline page for navigation requests
  if (request.mode === 'navigate') {
    const cache = await caches.open(STATIC_CACHE);
    const offlineResponse = await cache.match('/');
    
    if (offlineResponse) {
      return offlineResponse;
    }
  }
  
  // Return placeholder for images
  if (request.destination === 'image') {
    return new Response(
      '<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200"><rect width="200" height="200" fill="#f0f0f0"/><text x="100" y="100" text-anchor="middle" dy=".3em" fill="#999">Image Unavailable</text></svg>',
      {
        headers: {
          'Content-Type': 'image/svg+xml',
          'Cache-Control': 'no-cache'
        }
      }
    );
  }
  
  // Return generic error response
  return new Response('Service Unavailable', {
    status: 503,
    statusText: 'Service Unavailable',
    headers: {
      'Content-Type': 'text/plain',
      'Cache-Control': 'no-cache'
    }
  });
}

// Background sync for failed requests
self.addEventListener('sync', (event) => {
  if (event.tag === 'background-sync') {
    event.waitUntil(handleBackgroundSync());
  }
});

async function handleBackgroundSync() {
  console.log('Service Worker: Handling background sync');
  
  // Get failed requests from IndexedDB and retry them
  // This would be implemented based on your specific needs
}

// Push notifications
self.addEventListener('push', (event) => {
  if (!event.data) return;
  
  const data = event.data.json();
  const options = {
    body: data.body,
    icon: '/logo.png',
    badge: '/favicon.ico',
    data: data.data,
    actions: data.actions || []
  };
  
  event.waitUntil(
    self.registration.showNotification(data.title, options)
  );
});

// Notification click handling
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  
  if (event.action) {
    // Handle action clicks
    console.log('Notification action clicked:', event.action);
  } else {
    // Handle notification click
    event.waitUntil(
      clients.openWindow('/')
    );
  }
});

// Message handling from main thread
self.addEventListener('message', (event) => {
  const { type, payload } = event.data;
  
  switch (type) {
    case 'SKIP_WAITING':
      self.skipWaiting();
      break;
      
    case 'GET_CACHE_STATS':
      getCacheStats().then(stats => {
        event.ports[0].postMessage({ type: 'CACHE_STATS', payload: stats });
      });
      break;
      
    case 'CLEAR_CACHE':
      clearCache(payload.cacheName).then(() => {
        event.ports[0].postMessage({ type: 'CACHE_CLEARED' });
      });
      break;
      
    case 'PREFETCH_URLS':
      prefetchUrls(payload.urls).then(() => {
        event.ports[0].postMessage({ type: 'PREFETCH_COMPLETE' });
      });
      break;
  }
});

// Get cache statistics
async function getCacheStats() {
  const cacheNames = await caches.keys();
  const stats = {};
  
  for (const cacheName of cacheNames) {
    const cache = await caches.open(cacheName);
    const keys = await cache.keys();
    stats[cacheName] = keys.length;
  }
  
  return stats;
}

// Clear specific cache
async function clearCache(cacheName) {
  if (cacheName) {
    await caches.delete(cacheName);
  } else {
    const cacheNames = await caches.keys();
    await Promise.all(cacheNames.map(name => caches.delete(name)));
  }
}

// Prefetch URLs
async function prefetchUrls(urls) {
  const cache = await caches.open(DYNAMIC_CACHE);
  
  const prefetchPromises = urls.map(async (url) => {
    try {
      const response = await fetch(url);
      if (response.ok) {
        await cache.put(url, response);
      }
    } catch (error) {
      console.warn('Failed to prefetch:', url, error);
    }
  });
  
  await Promise.allSettled(prefetchPromises);
}

console.log('Service Worker: Loaded and ready');
