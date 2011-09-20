module Window (
    -- * Types & constructors
      Win (..), win
    -- * Constants
    , windowWidth, windowHeight
    -- * Functions
    , featuresPos, windowsPos, getValue, normalizeSum
) where

import Data.Int
import Data.Word

import qualified IntegralImage as II
import Primitives

data Win = Win {
      wRect :: Rect
    , wIntegral :: II.IntegralImage
    , wDeviation :: Double
    , wAvg :: Double
    } deriving (Show)

-- Default window's size
windowWidth = 24
windowHeight = 24

-- | Construct a new 'Win' object, computing the standard derivation.
win rect@(Rect x y w h) integral squaredIntegral =
    Win rect integral deriv avg
  where
    deriv = sqrt $ (squaresSum / n) - avg^2
    n = double w * double h
    valuesSum = double $ sumRectangle integral
    avg = valuesSum / n
    squaresSum = double $ sumRectangle squaredIntegral
    
    -- Compute the sum of the rectangle's surface using an 'IntegralImage'
    sumRectangle image =
        -- a ------- b
        -- -         -
        -- -    S    -
        -- -         -
        -- c ------- d
        let a = II.getValue image x y
            b = II.getValue image (x+w) y
            c = II.getValue image x (y+h)
            d = II.getValue image (x+w) (y+h)
        in d + a - b - c

-- | List all features positions and sizes inside the default window.
featuresPos minWidth minHeight =
    rectanglesPos minWidth minHeight windowWidth windowHeight

-- | List all windows for any positions and sizes inside an image.
windowsPos integral squaredIntegral =
    let Size w h = II.imageSize integral
    in [ win rect integral squaredIntegral |
           rect <- rectanglesPos windowWidth windowHeight w h
       ]

-- | Get the value of a point inside the window.
getValue (Win (Rect winX winY w h) image _ _) x y =
    ratio $ II.getValue image destX destY
  where
    -- New coordinates with the Window's ratio
    destX = winX + (x * w `div` windowWidth)
    destY = winY + (y * h `div` windowHeight)
    n = int w * int h
    -- Sum with the window's size ratio
    ratio s = s * int windowWidth * int windowHeight `div` int w `div` int h
    
-- | Sum normalized by the window's standard derivation
normalizeSum (Win _ _ deriv avg) n s =
    n * (round $ normalize (double s / double n))
  where
    -- Pixel's value normalized with the double of the standard derivation
    -- (95% of pixels values), average around 127
    normalize p = (p - (avg - 2*deriv)) * (255 / (4*deriv))

-- | List all rectangle positions and sizes inside a rectangle of width * height
rectanglesPos minWidth minHeight width height =
    [ Rect x y w h |
          x <- [0,incrX..width-minWidth]
        , y <- [0,incrY..height-minHeight]
        , w <- [minWidth,minWidth+incrWidth..width-x]
        , h <- [minHeight,minHeight+incrHeight..height-y]
    ]
  where
    incrMult = 5
    incrX = 1 * incrMult
    incrY = 1 * incrMult
    incrWidth = minWidth * incrMult
    incrHeight = minHeight * incrMult

double :: (Integral a) => a -> Double
double = fromIntegral
int :: (Integral a) => a -> Int64
int = fromIntegral