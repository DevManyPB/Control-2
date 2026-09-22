/**
 * ALUNA PBR-02 — MOTOR DE PRESENTACIÓN INTERACTIVA
 * Transiciones Suaves y Cinemáticas (Anime.js), Lightbox Modal y Controles de Auditorio
 */

document.addEventListener('DOMContentLoaded', () => {
    // =========================================================================
    // ELEMENTOS DEL DOM
    // =========================================================================
    const slides = Array.from(document.querySelectorAll('.slide'));
    const totalSlides = slides.length;
    const dotsContainer = document.getElementById('slide-dots');
    
    const btnPrev = document.getElementById('btn-prev');
    const btnNext = document.getElementById('btn-next');
    const btnPlay = document.getElementById('btn-play');
    const btnFullscreen = document.getElementById('btn-fullscreen');
    
    const iconPlay = document.getElementById('icon-play');
    const iconPause = document.getElementById('icon-pause');
    const progressFill = document.getElementById('progress-fill');
    const hudCounter = document.getElementById('hud-counter');
    const hudTitle = document.getElementById('hud-current-title');

    // Modal Lightbox
    const imageModal = document.getElementById('image-modal');
    const modalImg = document.getElementById('modal-img');
    const modalCaption = document.getElementById('modal-caption');
    const modalCloseBtn = document.getElementById('modal-close-btn');
    const modalBackdrop = document.getElementById('modal-backdrop');

    let currentSlide = 0;
    let isAutoplay = false;
    let autoplayTimer = null;
    let isAnimating = false; // Bloqueo de concurrencia para evitar saltos bruscos
    const AUTOPLAY_INTERVAL = 16000; // 16 segundos por diapositiva

    // =========================================================================
    // CREACIÓN DINÁMICA DE PUNTOS DE NAVEGACIÓN (DOTS)
    // =========================================================================
    slides.forEach((slide, index) => {
        const dot = document.createElement('button');
        dot.className = `slide-dot ${index === 0 ? 'active' : ''}`;
        dot.setAttribute('aria-label', `Ir a diapositiva ${index + 1}`);
        dot.setAttribute('data-title', slide.dataset.title || `Slide ${index + 1}`);
        dot.addEventListener('click', () => goToSlide(index));
        dotsContainer.appendChild(dot);
    });

    const dots = Array.from(document.querySelectorAll('.slide-dot'));

    // =========================================================================
    // TRANSICIÓN CINEMÁTICA Y SUAVE ENTRE DIAPOSITIVAS
    // =========================================================================
    function goToSlide(targetIndex) {
        if (targetIndex < 0 || targetIndex >= totalSlides || targetIndex === currentSlide || isAnimating) return;

        isAnimating = true;
        const outgoingSlide = slides[currentSlide];
        const incomingSlide = slides[targetIndex];
        const isForward = targetIndex > currentSlide;

        // 1. Transición suave de salida (Desvanecimiento calmado)
        anime({
            targets: outgoingSlide,
            opacity: [1, 0],
            translateY: [0, isForward ? -10 : 10],
            scale: [1, 0.985],
            duration: 450,
            easing: 'cubicBezier(0.4, 0, 0.2, 1)',
            complete: () => {
                outgoingSlide.classList.remove('active');
                outgoingSlide.style.transform = '';
            }
        });

        // 2. Entrada de la nueva diapositiva (Aparición gradual)
        incomingSlide.classList.add('active');
        incomingSlide.style.opacity = 0;

        anime({
            targets: incomingSlide,
            opacity: [0, 1],
            translateY: [isForward ? 12 : -12, 0],
            scale: [0.985, 1],
            duration: 750,
            easing: 'cubicBezier(0.16, 1, 0.3, 1)',
            complete: () => {
                isAnimating = false;
            }
        });

        // 3. Animación escalonada (Stagger) de los elementos de contenido
        const animatedElements = incomingSlide.querySelectorAll(
            '.glass-panel, .feature-card, .contrast-box, .math-card, .gallery-card, .trouble-card, .stack-card, .range-zone, .stat-highlight, .banner-note, .budget-total-box, .styled-table'
        );

        if (animatedElements.length > 0) {
            anime({
                targets: animatedElements,
                opacity: [0, 1],
                translateY: [15, 0],
                delay: anime.stagger(55, { start: 160 }),
                duration: 550,
                easing: 'easeOutCubic'
            });
        }

        // 4. Actualizar estados del sistema
        currentSlide = targetIndex;
        updateUI();

        // Renderizar KaTeX si hay fórmulas presentes
        if (window.renderMathInElement) {
            renderMathInElement(incomingSlide, {
                delimiters: [
                    { left: '$$', right: '$$', display: true },
                    { left: '$', right: '$', display: false }
                ],
                throwOnError: false
            });
        }

        // Reiniciar temporizador si autoplay está activo
        if (isAutoplay) {
            resetAutoplayTimer();
        }
    }

    function nextSlide() {
        if (currentSlide < totalSlides - 1) {
            goToSlide(currentSlide + 1);
        } else if (isAutoplay) {
            goToSlide(0);
        }
    }

    function prevSlide() {
        if (currentSlide > 0) {
            goToSlide(currentSlide - 1);
        }
    }

    // =========================================================================
    // ACTUALIZACIÓN DE LA INTERFAZ DE USUARIO (HUD)
    // =========================================================================
    function updateUI() {
        const progressPercentage = ((currentSlide + 1) / totalSlides) * 100;
        progressFill.style.width = `${progressPercentage}%`;

        const currentStr = String(currentSlide + 1).padStart(2, '0');
        const totalStr = String(totalSlides).padStart(2, '0');
        hudCounter.textContent = `${currentStr} / ${totalStr}`;

        hudTitle.textContent = slides[currentSlide].dataset.title || `Diapositiva ${currentSlide + 1}`;

        dots.forEach((dot, index) => {
            dot.classList.toggle('active', index === currentSlide);
        });

        btnPrev.style.opacity = currentSlide === 0 ? '0.35' : '1';
        btnNext.style.opacity = currentSlide === totalSlides - 1 && !isAutoplay ? '0.35' : '1';
    }

    // =========================================================================
    // MODAL LIGHTBOX (VISUALIZADOR EN ALTA RESOLUCIÓN)
    // =========================================================================
    const zoomableImages = document.querySelectorAll('.zoomable');

    zoomableImages.forEach(img => {
        img.addEventListener('click', (e) => {
            e.stopPropagation();
            openImageModal(img.src, img.getAttribute('data-caption') || img.alt);
        });
    });

    function openImageModal(src, captionText) {
        modalImg.src = src;
        modalCaption.textContent = captionText || '';
        imageModal.classList.add('active');
        imageModal.setAttribute('aria-hidden', 'false');

        // Animar la apertura con Anime.js
        anime({
            targets: '.modal-container',
            scale: [0.92, 1],
            opacity: [0, 1],
            duration: 350,
            easing: 'easeOutCubic'
        });
    }

    function closeImageModal() {
        anime({
            targets: '.modal-container',
            scale: [1, 0.94],
            opacity: [1, 0],
            duration: 250,
            easing: 'easeInQuad',
            complete: () => {
                imageModal.classList.remove('active');
                imageModal.setAttribute('aria-hidden', 'true');
                modalImg.src = '';
            }
        });
    }

    modalCloseBtn.addEventListener('click', closeImageModal);
    modalBackdrop.addEventListener('click', closeImageModal);

    // =========================================================================
    // MODO AUTOPLAY
    // =========================================================================
    function toggleAutoplay() {
        isAutoplay = !isAutoplay;
        if (isAutoplay) {
            iconPlay.style.display = 'none';
            iconPause.style.display = 'block';
            btnPlay.classList.add('playing');
            resetAutoplayTimer();
        } else {
            iconPlay.style.display = 'block';
            iconPause.style.display = 'none';
            btnPlay.classList.remove('playing');
            clearInterval(autoplayTimer);
        }
    }

    function resetAutoplayTimer() {
        clearInterval(autoplayTimer);
        autoplayTimer = setInterval(() => {
            nextSlide();
        }, AUTOPLAY_INTERVAL);
    }

    // =========================================================================
    // PANTALLA COMPLETA
    // =========================================================================
    function toggleFullscreen() {
        if (!document.fullscreenElement) {
            document.documentElement.requestFullscreen().catch(err => {
                console.warn(`Error al activar pantalla completa: ${err.message}`);
            });
        } else {
            if (document.exitFullscreen) {
                document.exitFullscreen();
            }
        }
    }

    // =========================================================================
    // EVENT LISTENERS (TECLADO Y AUDITORIO)
    // =========================================================================
    btnNext.addEventListener('click', nextSlide);
    btnPrev.addEventListener('click', prevSlide);
    btnPlay.addEventListener('click', toggleAutoplay);
    btnFullscreen.addEventListener('click', toggleFullscreen);

    document.addEventListener('keydown', (e) => {
        // Si el modal está abierto, Esc lo cierra y cancela el paso de diapositiva
        if (imageModal.classList.contains('active')) {
            if (e.key === 'Escape') {
                e.preventDefault();
                closeImageModal();
            }
            return;
        }

        if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') return;

        switch(e.key) {
            case 'ArrowRight':
            case 'PageDown':
            case ' ':
                e.preventDefault();
                nextSlide();
                break;
            case 'ArrowLeft':
            case 'PageUp':
            case 'Backspace':
                e.preventDefault();
                prevSlide();
                break;
            case 'Home':
                e.preventDefault();
                goToSlide(0);
                break;
            case 'End':
                e.preventDefault();
                goToSlide(totalSlides - 1);
                break;
            case 'f':
            case 'F':
                e.preventDefault();
                toggleFullscreen();
                break;
            case 'p':
            case 'P':
                e.preventDefault();
                toggleAutoplay();
                break;
            // Salto rápido numérico (Teclas 1 a 9)
            case '1': case '2': case '3': case '4': case '5':
            case '6': case '7': case '8': case '9':
                const slideNum = parseInt(e.key, 10) - 1;
                if (slideNum < totalSlides) {
                    goToSlide(slideNum);
                }
                break;
        }
    });

    // Soporte táctil en pantalla táctil o tableta
    let touchStartX = 0;
    let touchEndX = 0;

    document.addEventListener('touchstart', (e) => {
        touchStartX = e.changedTouches[0].screenX;
    }, { passive: true });

    document.addEventListener('touchend', (e) => {
        touchEndX = e.changedTouches[0].screenX;
        handleSwipe();
    }, { passive: true });

    function handleSwipe() {
        if (imageModal.classList.contains('active')) return;
        const threshold = 60;
        if (touchEndX < touchStartX - threshold) {
            nextSlide();
        }
        if (touchEndX > touchStartX + threshold) {
            prevSlide();
        }
    }

    // =========================================================================
    // PARTÍCULAS BIO-MARINAS EN EL LIENZO DE FONDO
    // =========================================================================
    const canvas = document.getElementById('particles-canvas');
    if (canvas) {
        const ctx = canvas.getContext('2d');
        let width = canvas.width = window.innerWidth;
        let height = canvas.height = window.innerHeight;

        window.addEventListener('resize', () => {
            width = canvas.width = window.innerWidth;
            height = canvas.height = window.innerHeight;
        });

        const particles = [];
        const PARTICLE_COUNT = 38; // Densidad calibrada para no distraer la atención

        for (let i = 0; i < PARTICLE_COUNT; i++) {
            particles.push({
                x: Math.random() * width,
                y: Math.random() * height,
                radius: Math.random() * 1.8 + 0.6,
                vx: (Math.random() - 0.5) * 0.25,
                vy: (Math.random() - 0.5) * 0.25,
                alpha: Math.random() * 0.45 + 0.1,
                color: Math.random() > 0.4 ? '56, 189, 248' : '52, 211, 153'
            });
        }

        function animateParticles() {
            ctx.clearRect(0, 0, width, height);

            for (let i = 0; i < particles.length; i++) {
                const p = particles[i];
                p.x += p.vx;
                p.y += p.vy;

                if (p.x < 0) p.x = width;
                if (p.x > width) p.x = 0;
                if (p.y < 0) p.y = height;
                if (p.y > height) p.y = 0;

                ctx.beginPath();
                ctx.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
                ctx.fillStyle = `rgba(${p.color}, ${p.alpha})`;
                ctx.fill();
            }

            requestAnimationFrame(animateParticles);
        }

        animateParticles();
    }

    // Inicializar UI
    updateUI();
});
