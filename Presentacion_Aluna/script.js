document.addEventListener('DOMContentLoaded', () => {
    // ========== REFERENCES ==========
    const slides = document.querySelectorAll('.slide');
    const total = slides.length;
    let current = 0;
    let isPlaying = true;
    let progressAnim = null;
    const DURATION = 20000;

    const progressBar = document.getElementById('progress-bar');
    const btnPrev = document.getElementById('btn-prev');
    const btnNext = document.getElementById('btn-next');
    const btnPlayPause = document.getElementById('btn-play-pause');
    const iconPlay = document.getElementById('icon-play');
    const iconPause = document.getElementById('icon-pause');
    const slideNum = document.getElementById('slide-num');
    const dotsContainer = document.getElementById('slide-dots');

    const charEls = {
        frailejon: document.getElementById('char-frailejon'),
        chlorella: document.getElementById('char-chlorella'),
        reactor: document.getElementById('char-reactor')
    };

    // ========== PARTICLES (Canvas) ==========
    const canvas = document.getElementById('particles-canvas');
    const ctx = canvas.getContext('2d');
    let particles = [];

    function resizeCanvas() {
        canvas.width = window.innerWidth;
        canvas.height = window.innerHeight;
    }
    resizeCanvas();
    window.addEventListener('resize', resizeCanvas);

    class Particle {
        constructor() {
            this.reset();
        }
        reset() {
            this.x = Math.random() * canvas.width;
            this.y = Math.random() * canvas.height;
            this.size = Math.random() * 3 + 1;
            this.speedX = (Math.random() - 0.5) * 0.3;
            this.speedY = -Math.random() * 0.4 - 0.1;
            this.opacity = Math.random() * 0.3 + 0.05;
            this.life = 0;
            this.maxLife = Math.random() * 600 + 300;
        }
        update() {
            this.x += this.speedX;
            this.y += this.speedY;
            this.life++;
            if (this.life > this.maxLife || this.y < -10 || this.x < -10 || this.x > canvas.width + 10) {
                this.reset();
                this.y = canvas.height + 10;
            }
        }
        draw() {
            const fade = 1 - Math.abs((this.life / this.maxLife) - 0.5) * 2;
            ctx.beginPath();
            ctx.arc(this.x, this.y, this.size, 0, Math.PI * 2);
            ctx.fillStyle = `rgba(82, 183, 136, ${this.opacity * fade})`;
            ctx.fill();
        }
    }

    for (let i = 0; i < 60; i++) particles.push(new Particle());

    function animateParticles() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        particles.forEach(p => { p.update(); p.draw(); });
        requestAnimationFrame(animateParticles);
    }
    animateParticles();

    // ========== DOTS ==========
    for (let i = 0; i < total; i++) {
        const dot = document.createElement('button');
        dot.classList.add('dot');
        if (i === 0) dot.classList.add('active');
        dot.addEventListener('click', () => goTo(i));
        dotsContainer.appendChild(dot);
    }
    const dots = dotsContainer.querySelectorAll('.dot');

    // ========== CHARACTER FLOATING ==========
    Object.values(charEls).forEach(el => {
        anime({
            targets: el,
            translateY: ['-18px', '18px'],
            rotate: ['-1.5deg', '1.5deg'],
            direction: 'alternate',
            loop: true,
            easing: 'easeInOutSine',
            duration: 3500 + Math.random() * 2000
        });
    });

    // ========== SLIDE TRANSITION ==========
    function goTo(index, direction) {
        if (index === current) return;
        if (direction === undefined) direction = index > current ? 'next' : 'prev';

        const leaving = slides[current];
        const entering = slides[index];
        const leavingChar = leaving.dataset.char;
        const enteringChar = entering.dataset.char;

        const isMobile = window.innerWidth <= 768;
        
        // Calculate positions
        // If no char, center the slide. If char, align left.
        const getLeftPos = (charType, el) => {
            if (isMobile) return '7%';
            // Use percentage for center to avoid resize issues
            return charType !== 'none' ? '6%' : '25%'; 
        };

        // For screens between 768px and 1100px, 25% might not be perfectly centered since width is 65%. 
        // We can do calc(50% - width/2)
        const getExactLeftPos = (charType, el) => {
            if (isMobile) return '7%';
            if (charType !== 'none') return '6%';
            
            const w = el.offsetWidth;
            const screenW = window.innerWidth;
            return ((screenW - w) / 2) + 'px';
        };

        const currentPos = getExactLeftPos(leavingChar, leaving);
        const targetPos = getExactLeftPos(enteringChar, entering);

        // --- Animate OUT ---
        const leavingEls = leaving.querySelectorAll('.card-tag, h1, h2, .card-lead, li, .card-chips, .card-note, blockquote, .comparison, .equation-box, .metrics-grid, .team-grid');
        anime.remove(leaving);
        anime.remove(leavingEls);
        
        anime({
            targets: leavingEls,
            opacity: 0,
            translateY: -15,
            duration: 300,
            easing: 'easeInQuad',
            delay: anime.stagger(30)
        });
        
        anime({
            targets: leaving,
            opacity: 0,
            left: targetPos, // Move towards the target position of the next slide
            scale: 0.97,
            duration: 600,
            easing: 'easeInOutCubic',
            complete: () => { leaving.classList.remove('active'); }
        });

        // --- Animate IN ---
        entering.classList.add('active');
        anime.set(entering, { opacity: 0, left: currentPos, scale: 0.97, translateX: 0 }); // Start at current position
        
        anime({
            targets: entering,
            opacity: 1,
            left: targetPos, // Move to its proper position
            scale: 1,
            duration: 800,
            easing: 'easeInOutCubic',
            delay: 100
        });

        const enteringEls = entering.querySelectorAll('.card-tag, h1, h2, .card-lead, li, .card-chips, .card-note, blockquote, .comparison, .equation-box, .metrics-grid, .team-grid');
        anime.set(enteringEls, { opacity: 0, translateY: 25 });
        anime({
            targets: enteringEls,
            opacity: 1,
            translateY: 0,
            duration: 700,
            easing: 'easeOutQuart',
            delay: anime.stagger(60, { start: 400 })
        });

        // --- Character swap ---
        if (leavingChar !== enteringChar) {
            if (leavingChar && leavingChar !== 'none' && charEls[leavingChar]) {
                anime({
                    targets: charEls[leavingChar],
                    opacity: 0,
                    scale: 0.85,
                    translateX: 80,
                    duration: 500,
                    easing: 'easeInQuad'
                });
            }
            if (enteringChar && enteringChar !== 'none' && charEls[enteringChar]) {
                anime({
                    targets: charEls[enteringChar],
                    opacity: [0, 1],
                    scale: [0.85, 1],
                    translateX: [80, 0],
                    duration: 1000,
                    easing: 'easeOutElastic(1, .7)',
                    delay: 400,
                    complete: function(anim) {
                        anime({
                            targets: charEls[enteringChar],
                            translateY: [-12, 0],
                            duration: 2500,
                            direction: 'alternate',
                            loop: true,
                            easing: 'easeInOutSine'
                        });
                    }
                });
            }
        }

        // --- Update dots & counter ---
        dots[current].classList.remove('active');
        dots[index].classList.add('active');
        current = index;
        slideNum.textContent = String(current + 1).padStart(2, '0');

        resetProgress();
    }

    function next() { goTo((current + 1) % total, 'next'); }
    function prev() { goTo((current - 1 + total) % total, 'prev'); }

    // ========== PROGRESS & AUTO-PLAY ==========
    function startProgress() {
        if (!isPlaying) return;
        progressAnim = anime({
            targets: progressBar,
            width: ['0%', '100%'],
            duration: DURATION,
            easing: 'linear',
            complete: () => { if (isPlaying) next(); }
        });
    }

    function resetProgress() {
        if (progressAnim) progressAnim.pause();
        progressBar.style.width = '0%';
        if (isPlaying) startProgress();
    }

    function togglePlay() {
        isPlaying = !isPlaying;
        if (isPlaying) {
            iconPlay.style.display = 'none';
            iconPause.style.display = 'block';
            startProgress();
        } else {
            iconPlay.style.display = 'block';
            iconPause.style.display = 'none';
            if (progressAnim) progressAnim.pause();
        }
    }

    // ========== EVENT LISTENERS ==========
    btnNext.addEventListener('click', () => { next(); });
    btnPrev.addEventListener('click', () => { prev(); });
    btnPlayPause.addEventListener('click', togglePlay);

    // Keyboard support
    document.addEventListener('keydown', (e) => {
        if (e.key === 'ArrowRight' || e.key === ' ') { e.preventDefault(); next(); }
        if (e.key === 'ArrowLeft') { e.preventDefault(); prev(); }
        if (e.key === 'p' || e.key === 'P') { togglePlay(); }
    });

    // ========== PRINT TO PDF ==========
    const btnPrint = document.getElementById('btn-print');
    if (btnPrint) {
        btnPrint.addEventListener('click', () => {
            const isWasPlaying = isPlaying;
            if (isPlaying) togglePlay(); // Pause presentation
            
            // Inject images into slides for print mode
            slides.forEach(slide => {
                const char = slide.getAttribute('data-char');
                if (char && char !== 'none') {
                    const imgUrl = char === 'frailejon' ? 'frailejon_character_1786323422099.png' :
                                   char === 'chlorella' ? 'chlorella_character_1786323439290.png' :
                                   'bioreactor_cartoon_1786323446804.png';
                    const img = document.createElement('img');
                    img.src = imgUrl;
                    img.className = `print-char print-char-${char}`;
                    slide.appendChild(img);
                }
            });

            // Allow DOM to update then call native print
            setTimeout(() => {
                window.print();
                
                // Cleanup injected images
                document.querySelectorAll('.print-char').forEach(img => img.remove());
                if (isWasPlaying) togglePlay(); // Resume
            }, 300);
        });
    }

    // ========== INITIAL STATE ==========
    // Hide all text elements initially
    slides.forEach((slide, i) => {
        if (i !== 0) {
            anime.set(slide, { opacity: 0 });
        }
    });

    // Animate first slide in
    const firstEls = slides[0].querySelectorAll('.card-tag, h1, h2, .card-lead, li, .card-chips, .card-note, blockquote, .comparison, .equation-box, .metrics-grid, .team-grid');
    anime.set(firstEls, { opacity: 0, translateY: 25 });
    anime({
        targets: firstEls,
        opacity: 1,
        translateY: 0,
        duration: 800,
        easing: 'easeOutQuart',
        delay: anime.stagger(120, { start: 300 })
    });

    startProgress();
});
