// GitHub API Configuration
const GITHUB_REPO = 'prateek54353/PaperWise';
const GITHUB_API_URL = `https://api.github.com/repos/${GITHUB_REPO}/releases`;

// Discord Server Configuration
const DISCORD_INVITE_URL = 'https://discord.gg/KjeTgENPbE';

// Fetch GitHub Releases
async function fetchGitHubReleases() {
    try {
        const response = await fetch(GITHUB_API_URL);
        if (!response.ok) {
            throw new Error('Failed to fetch releases');
        }
        const releases = await response.json();
        return releases.filter(release => !release.prerelease); // Filter out pre-releases
    } catch (error) {
        console.error('Error fetching GitHub releases:', error);
        return [];
    }
}

// Update download section with latest release info
async function updateDownloadSection() {
    const releases = await fetchGitHubReleases();
    const versionInfoContainer = document.getElementById('version-info');
    
    if (!versionInfoContainer) return;

    if (releases.length === 0) {
        // Set fallback values if API fails
        versionInfoContainer.innerHTML = `
            <div class="version-details">
                <div class="version-item">
                    <span class="version-label">Latest Version:</span>
                    <span class="version-value">v2.6.2</span>
                </div>
                <div class="version-item">
                    <span class="version-label">Released:</span>
                    <span class="version-value">September 2026</span>
                </div>
                <div class="version-item">
                    <span class="version-label">Android:</span>
                    <span class="version-value">5.0+</span>
                </div>
                <div class="version-item">
                    <span class="version-label">License:</span>
                    <span class="version-value">MIT</span>
                </div>
            </div>
        `;
        return;
    }

    const latestRelease = releases[0];
    
    // Update release date
    const releaseDate = new Date(latestRelease.published_at);
    const formattedDate = releaseDate.toLocaleDateString('en-US', { 
        year: 'numeric', 
        month: 'long' 
    });

    // Dynamically populate version info
    versionInfoContainer.innerHTML = `
        <div class="version-details">
            <div class="version-item">
                <span class="version-label">Latest Version:</span>
                <span class="version-value">${latestRelease.tag_name}</span>
            </div>
            <div class="version-item">
                <span class="version-label">Released:</span>
                <span class="version-value">${formattedDate}</span>
            </div>
            <div class="version-item">
                <span class="version-label">Android:</span>
                <span class="version-value">5.0+</span>
            </div>
            <div class="version-item">
                <span class="version-label">License:</span>
                <span class="version-value">MIT</span>
            </div>
        </div>
    `;

    // Update GitHub releases link
    const githubReleaseLink = document.querySelector('a[href*="github.com/prateek54353/PaperWise/releases"]');
    if (githubReleaseLink) {
        githubReleaseLink.href = latestRelease.html_url;
    }

    // Update download button to point to latest release
    const downloadButtons = document.querySelectorAll('.download-card[href*="github.com"]');
    downloadButtons.forEach(button => {
        button.href = latestRelease.html_url;
    });

    // Update hero badge with latest version
    const heroBadgeText = document.getElementById('hero-badge-text');
    if (heroBadgeText) {
        heroBadgeText.textContent = `🚀 ${latestRelease.tag_name} Now Available`;
    }
}

// Update version history section
async function updateVersionHistory() {
    const releases = await fetchGitHubReleases();
    const timelineContainer = document.getElementById('version-timeline');
    if (!timelineContainer) return;

    // Clear existing content
    timelineContainer.innerHTML = '';

    if (releases.length === 0) {
        timelineContainer.innerHTML = '<div class="loading-placeholder">Unable to load recent updates. Please check back later.</div>';
        return;
    }

    // Add recent releases from GitHub (limit to 5 releases)
    const recentReleases = releases.slice(0, 5);
    
    recentReleases.forEach(release => {
        const releaseDate = new Date(release.published_at);
        const formattedDate = releaseDate.toLocaleDateString('en-US', { 
            year: 'numeric', 
            month: 'long' 
        });

        const timelineItem = document.createElement('div');
        timelineItem.className = 'timeline-item';
        
        // Parse release notes (take first few lines/bullet points)
        const releaseNotes = release.body || 'No release notes available.';
        const notesLines = releaseNotes.split('\n').filter(line => line.trim().length > 0).slice(0, 5);
        
        const featuresList = notesLines.map(line => {
            // Clean up markdown formatting
            const cleanLine = line.replace(/^[-*+]\s*/, '').replace(/^#{1,6}\s*/, '');
            return `<li>${cleanLine}</li>`;
        }).join('');

        timelineItem.innerHTML = `
            <div class="timeline-version">${release.tag_name}</div>
            <div class="timeline-date">${formattedDate}</div>
            <div class="timeline-content">
                <h3>${release.name || release.tag_name}</h3>
                <ul>
                    ${featuresList}
                </ul>
            </div>
        `;
        
        timelineContainer.appendChild(timelineItem);
    });
}

// Add Discord server link
function addDiscordLink() {
    // Only add Discord links on the main page (not privacy page)
    if (!document.querySelector('.hero')) return;

    // Add Discord link to navigation
    const navMenu = document.querySelector('.nav-menu');
    if (navMenu && !navMenu.querySelector('a[href*="discord.gg"]')) {
        const discordLi = document.createElement('li');
        discordLi.innerHTML = `
            <a href="${DISCORD_INVITE_URL}" target="_blank" rel="noopener noreferrer">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor" style="vertical-align: middle; margin-right: 5px;">
                    <path d="M20.317 4.37a19.791 19.791 0 0 0-4.885-1.515.074.074 0 0 0-.079.037c-.21.375-.444.864-.608 1.25a18.27 18.27 0 0 0-5.487 0 12.64 12.64 0 0 0-.617-1.25.077.077 0 0 0-.079-.037A19.736 19.736 0 0 0 3.677 4.37a.07.07 0 0 0-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 0 0 .031.057 19.9 19.9 0 0 0 5.993 3.03.078.078 0 0 0 .084-.028 14.09 14.09 0 0 0 1.226-1.994.076.076 0 0 0-.041-.106 13.107 13.107 0 0 1-1.872-.892.077.077 0 0 1-.008-.128 10.2 10.2 0 0 0 .372-.292.074.074 0 0 1 .077-.01c3.928 1.793 8.18 1.793 12.062 0a.074.074 0 0 1 .078.01c.12.098.246.198.373.292a.077.077 0 0 1-.006.127 12.299 12.299 0 0 1-1.873.892.077.077 0 0 0-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 0 0 .084.028 19.839 19.839 0 0 0 6.002-3.03.077.077 0 0 0 .032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 0 0-.031-.03zM8.02 15.33c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.956-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.956 2.418-2.157 2.418zm7.975 0c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.955-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.946 2.418-2.157 2.418z"/>
                </svg>
                Discord
            </a>
        `;
        navMenu.appendChild(discordLi);
    }

    // Add Discord link to footer Connect section
    const connectSection = document.querySelector('.footer-section h4');
    if (connectSection && connectSection.textContent === 'Connect') {
        const connectList = connectSection.nextElementSibling;
        if (connectList && !connectList.querySelector('a[href*="discord.gg"]')) {
            const discordLi = document.createElement('li');
            discordLi.innerHTML = `
                <a href="${DISCORD_INVITE_URL}" target="_blank" rel="noopener noreferrer">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor" style="vertical-align: middle; margin-right: 5px;">
                        <path d="M20.317 4.37a19.791 19.791 0 0 0-4.885-1.515.074.074 0 0 0-.079.037c-.21.375-.444.864-.608 1.25a18.27 18.27 0 0 0-5.487 0 12.64 12.64 0 0 0-.617-1.25.077.077 0 0 0-.079-.037A19.736 19.736 0 0 0 3.677 4.37a.07.07 0 0 0-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 0 0 .031.057 19.9 19.9 0 0 0 5.993 3.03.078.078 0 0 0 .084-.028 14.09 14.09 0 0 0 1.226-1.994.076.076 0 0 0-.041-.106 13.107 13.107 0 0 1-1.872-.892.077.077 0 0 1-.008-.128 10.2 10.2 0 0 0 .372-.292.074.074 0 0 1 .077-.01c3.928 1.793 8.18 1.793 12.062 0a.074.074 0 0 1 .078.01c.12.098.246.198.373.292a.077.077 0 0 1-.006.127 12.299 12.299 0 0 1-1.873.892.077.077 0 0 0-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 0 0 .084.028 19.839 19.839 0 0 0 6.002-3.03.077.077 0 0 0 .032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 0 0-.031-.03zM8.02 15.33c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.956-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.956 2.418-2.157 2.418zm7.975 0c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.955-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.946 2.418-2.157 2.418z"/>
                    </svg>
                    Discord Server
                </a>
            `;
            connectList.appendChild(discordLi);
        }
    }

    // Add Discord link to support section
    const supportActions = document.querySelector('.support-actions');
    if (supportActions && !supportActions.querySelector('a[href*="discord.gg"]')) {
        const discordButton = document.createElement('a');
        discordButton.href = DISCORD_INVITE_URL;
        discordButton.target = '_blank';
        discordButton.rel = 'noopener noreferrer';
        discordButton.className = 'btn btn-secondary support-btn';
        discordButton.innerHTML = `
            <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
                <path d="M20.317 4.37a19.791 19.791 0 0 0-4.885-1.515.074.074 0 0 0-.079.037c-.21.375-.444.864-.608 1.25a18.27 18.27 0 0 0-5.487 0 12.64 12.64 0 0 0-.617-1.25.077.077 0 0 0-.079-.037A19.736 19.736 0 0 0 3.677 4.37a.07.07 0 0 0-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 0 0 .031.057 19.9 19.9 0 0 0 5.993 3.03.078.078 0 0 0 .084-.028 14.09 14.09 0 0 0 1.226-1.994.076.076 0 0 0-.041-.106 13.107 13.107 0 0 1-1.872-.892.077.077 0 0 1-.008-.128 10.2 10.2 0 0 0 .372-.292.074.074 0 0 1 .077-.01c3.928 1.793 8.18 1.793 12.062 0a.074.074 0 0 1 .078.01c.12.098.246.198.373.292a.077.077 0 0 1-.006.127 12.299 12.299 0 0 1-1.873.892.077.077 0 0 0-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 0 0 .084.028 19.839 19.839 19.839 0 0 0 6.002-3.03.077.077 0 0 0 .032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 0 0-.031-.03zM8.02 15.33c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.956-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.956 2.418-2.157 2.418zm7.975 0c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.955-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.946 2.418-2.157 2.418z"/>
            </svg>
            Join Discord
        `;
        supportActions.appendChild(discordButton);
    }
}

// Initialize all dynamic content
async function initializeDynamicContent() {
    try {
        await Promise.all([
            updateDownloadSection(),
            updateVersionHistory(),
        ]);
        addDiscordLink();
    } catch (error) {
        console.error('Error initializing dynamic content:', error);
    }
}

// Run when DOM is loaded
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeDynamicContent);
} else {
    initializeDynamicContent();
}
