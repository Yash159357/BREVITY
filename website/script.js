// DOM Content Loaded
document.addEventListener('DOMContentLoaded', function () {
    // Initialize Tailwind config
    tailwind.config = {
        theme: {
            extend: {
                colors: {
                    'brevity-blue': '#4F46E5',
                    'brevity-dark': '#0F172A',
                    'brevity-gray': '#1E293B',
                }
            }
        }
    };

    initializeAnimations();
    initializeCarousel();
    initializeNavbar();
    initializeFAQ();
    initializeHoverEffects();
    initializeLoadingAnimation();
});

// Smooth scroll for navigation links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

// FAQ Toggle Function
function initializeFAQ() {
    document.querySelectorAll('.faq-toggle').forEach(toggle => {
        toggle.addEventListener('click', function () {
            const target = this.getAttribute('data-target');
            const content = this.parentNode.querySelector('.faq-content');
            const icon = this.querySelector('.faq-icon');

            if (content.classList.contains('hidden')) {
                content.classList.remove('hidden');
                icon.style.transform = 'rotate(180deg)';
            } else {
                content.classList.add('hidden');
                icon.style.transform = 'rotate(0deg)';
            }
        });
    });
}

// Intersection Observer for animations
function initializeAnimations() {
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, observerOptions);

    // Observe all animated elements
    document.querySelectorAll('.animate-fade-in, .animate-slide-up, .animate-slide-in-left, .animate-slide-in-right').forEach(el => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(30px)';
        observer.observe(el);
    });
}

// Carousel functionality
function initializeCarousel() {
    const carousel = document.getElementById('carousel');
    if (!carousel) return;

    let currentSlide = 0;
    const slides = carousel.children.length;

    function autoScroll() {
        currentSlide = (currentSlide + 1) % slides;
        const scrollAmount = currentSlide * 320; // 320px = width + gap
        carousel.scrollTo({
            left: scrollAmount,
            behavior: 'smooth'
        });
    }

    // Auto-scroll every 4 seconds
    setInterval(autoScroll, 4000);
}

// Navbar background change on scroll
function initializeNavbar() {
    window.addEventListener('scroll', () => {
        const navbar = document.querySelector('nav');
        if (navbar) {
            if (window.scrollY > 50) {
                navbar.style.backgroundColor = 'rgba(15, 23, 42, 0.95)';
            } else {
                navbar.style.backgroundColor = 'rgba(15, 23, 42, 0.8)';
            }
        }
    });
}

// Hover effects
function initializeHoverEffects() {
    document.querySelectorAll('.hover-glow').forEach(card => {
        card.addEventListener('mouseenter', () => {
            card.style.transform = 'translateY(-8px)';
            card.style.boxShadow = '0 20px 40px rgba(79, 70, 229, 0.3)';
        });

        card.addEventListener('mouseleave', () => {
            card.style.transform = 'translateY(0)';
            card.style.boxShadow = 'none';
        });
    });
}

// Loading animation
function initializeLoadingAnimation() {
    window.addEventListener('load', () => {
        document.body.classList.add('loaded');
        document.body.style.opacity = '1';
    });
}

// Contact form validation (for contact page)
function validateContactForm() {
    const form = document.getElementById('contactForm');
    if (!form) return;

    form.addEventListener('submit', function (e) {
        e.preventDefault();

        const name = document.getElementById('name').value.trim();
        const email = document.getElementById('email').value.trim();
        const message = document.getElementById('message').value.trim();

        if (!name || !email || !message) {
            alert('Please fill in all fields');
            return;
        }

        if (!isValidEmail(email)) {
            alert('Please enter a valid email address');
            return;
        }

        // Simulate form submission
        alert('Thank you for your message! We\'ll get back to you soon.');
        form.reset();
    });
}

// Email validation helper
function isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

// Initialize contact form if on contact page
document.addEventListener('DOMContentLoaded', validateContactForm);

// Parallax effect for hero section
window.addEventListener('scroll', () => {
    const scrolled = window.pageYOffset;
    const heroSection = document.querySelector('section');
    const heroContent = heroSection?.querySelector('div');

    if (heroContent && scrolled < window.innerHeight) {
        heroContent.style.transform = `translateY(${scrolled * 0.1}px)`;
    }
});

// Mobile menu toggle (placeholder for future implementation)
function toggleMobileMenu() {
    console.log('Mobile menu toggled');
    // Implementation for mobile menu can be added here
}