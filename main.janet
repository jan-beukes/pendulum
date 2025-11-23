(use ./jaylib/build/jaylib)

(def screen-size 800)
(def center (/ screen-size 2))
(def gravity 900)

(def mass-colors [:red :green :blue :purple :gold :sky-blue])

(defn new-joint
  [pos mass &opt color]
  (default color :red)
  (assert (= (type pos) :tuple))
  @{:pos pos :mass mass :vel [0 0] :color color})

(defn new-pendulum
  [masses lengths angles colors]
  # the first element is the origin/pivot
  (var [x y] [center 100.0])
  (def pendulum @{:pos     @[[x y]]
                  :vel     @[[0.0 0.0]]
                  :masses  @[0.0]
                  :lengths @[0.0]
                  :colors  @[:black]
                  :count   (+ (length masses) 1)})
  (def origin [center 100])
  (for i 0 (length masses)
    (array/push (pendulum :masses) (masses i))
    (def len (lengths i))
    (array/push (pendulum :lengths) len)
    (+= x (* len (math/sin (angles i))))
    (-= y (* len (math/cos (angles i))))
    (array/push (pendulum :pos) [x y])
    (array/push (pendulum :vel) [0.0 0.0])
    (array/push (pendulum :colors) (colors i)))
  pendulum)


(defn update-pendulum
  [pendulum dt]
  (def {:pos positions :vel velocities :masses masses :lengths lengths} pendulum)
  (def prev-positions @[(positions 0)])
  # gravity
  (for i 1 (pendulum :count)
    (set (velocities i) (vector2-add (velocities i) [0.0 (* gravity dt)]))
    (array/push prev-positions (positions i))
    (set (positions i) (vector2-add (positions i) (vector2-scale (velocities i) dt))))

  # constraints
  (for i 1 (pendulum :count)
    (def [pos prev-pos] [(positions i) (positions (- i 1))])
    (def [mass prev-mass] [(masses i) (masses (- i 1))])
    (def len (lengths i))

    (def dist (vector2-distance prev-pos pos))
    (def w0 (if (> prev-mass 0.0) (/ 1.0 prev-mass) 0.0))
    (def w1 (if (> mass 0.0) (/ 1.0 mass) 0.0))
    (def corr (/ (/ (- len dist) dist) (+ w0 w1)))

    (def dx (- (pos 0) (prev-pos 0)))
    (def dy (- (pos 1) (prev-pos 1)))
    (set (positions (- i 1)) (vector2-sub (positions (- i 1)) [(* w0 corr dx) (* w0 corr dy)]))
    (set (positions i) (vector2-add (positions i) [(* w1 corr dx) (* w1 corr dy)])))

  # fuck me
  (if (> dt 0)
    (for i 1 (pendulum :count)
    (def [x  y] [((positions i) 0) ((positions i) 1)])
    (def [px py] [((prev-positions i) 0) ((prev-positions i) 1)])
    (def vx (/ (- x px) dt))
    (def vy (/ (- y py ) dt))
    (set (velocities i) [vx vy]))))

(defn draw-pendulum
  [pendulum]
  (def line-color :gray)
  (def line-width 4)
  (def mass-scale 40)
  (def positions (pendulum :pos))
  (var prev-pos (positions 0))
  (each pos (slice positions 1)
    (draw-line-ex prev-pos pos line-width line-color)
    (set prev-pos pos))
  (loop [i :down-to [(- (pendulum :count) 1) 1]]
    (def [pos mass color] [((pendulum :pos) i) ((pendulum :masses) i) ((pendulum :colors) i)])
    (draw-circle-v pos (* mass mass-scale) color)))

(defn clamp
  [x a b]
  (max a (min x b)))

(defn main
  [file &opt num]
  (default num "3")

  (def n (scan-number num))

  (if (nil? n) (do 
      (print "Error: arg must be a number")
      (os/exit 1)))
  (def n (math/floor n))

  (math/seedrandom (os/time))
  (def random-masses  |(catseq [_ :range [n]] (+ (math/random) 0.2)))
  (def random-angles  |(catseq [_ :range [n]] (- (* (math/random) 2 math/pi) math/pi)))
  (def random-lengths |(catseq [_ :range [n]] (+ (* (math/random) 160) 60)))
  (def random-colors
    |(catseq [_ :range [n]] (mass-colors
                              (math/floor (* (math/random) (- (length mass-colors) 1))))))

  (def masses (random-masses))
  (def lengths (random-lengths))
  (def angles (random-angles))
  (def colors (random-colors))
  (def pendulum (new-pendulum masses lengths angles colors))

  (def background-color 0x181818ff)
  (init-window screen-size screen-size "Pendulum")
  (set-target-fps 60)

  (def camera (camera-2d :target [center center]))
  (set (camera :offset) (camera :target))
  (set (camera :zoom) 1)

  (def substeps 10)
  (while (not (window-should-close))
    (def dt (get-frame-time))
    (def scroll (get-mouse-wheel-move))
    (cond 
      # zoom
      (not= scroll 0.0)
      (set (camera :zoom) (clamp (+ (math/exp (math/log (camera :zoom))) (* scroll 0.2)) 0.125 64.0))

      # move
      (key-down? :down)
      (set (camera :target) (vector2-add (camera :target) [0 (* 500 dt)]))
      (key-down? :up)
      (set (camera :target) (vector2-sub (camera :target) [0 (* 500 dt)])))


    (for i 0 substeps (update-pendulum pendulum (/ dt substeps)))
    (begin-drawing)
    (begin-mode-2d camera)
    (clear-background background-color)
    (draw-pendulum pendulum)
    (end-mode-2d)
    (end-drawing))
  (close-window))
