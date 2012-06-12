{-# LANGUAGE MultiParamTypeClasses #-}

module Vision.Image.RGBImage.Base (
    -- * Types & constructors
      RGBImage (..), RGBPixel (..)
    ) where

import Data.Word

import Data.Array.Repa (
      Array, D, DIM3, Z (..), (:.) (..), (!), unsafeIndex, fromListUnboxed
    , fromFunction, extent, delay
    )

import qualified Vision.Image.IImage as I
import Vision.Primitive (Point (..), Size (..))

-- | RGB image (y :. x :. channel).
newtype RGBImage = RGBImage (Array D DIM3 Word8)

data RGBPixel = RGBPixel {
      rgbRed ::   {-# UNPACK #-} !Word8
    , rgbGreen :: {-# UNPACK #-} !Word8
    , rgbBlue ::  {-# UNPACK #-} !Word8
    } deriving (Show, Read, Eq)

instance I.Image RGBImage RGBPixel Word8 where
    fromList size xs =
        RGBImage $ delay $ fromListUnboxed (imageShape size) $ 
            concat [ [r, b, b] | RGBPixel r g b <- xs ]
    {-# INLINE fromList #-}
    
    fromFunction size f =
        RGBImage $ fromFunction (imageShape size) $ \(Z :. y :. x :. c) ->
            let point = Point x y
            in case c of
                 0 -> rgbRed $ f point
                 1 -> rgbGreen $ f point
                 2 -> rgbBlue $ f point
    {-# INLINE fromFunction #-}

    getSize (RGBImage image) =
        let (Z :. h :. w :. _) = extent image
        in Size w h
    {-# INLINE getSize #-}

    RGBImage image `getPixel` Point x y =
        let coords = Z :. y :. x
        in RGBPixel {
              rgbRed = image ! (coords :. 0)
            , rgbGreen = image ! (coords :. 1)
            , rgbBlue = image ! (coords :. 2)
        }
    {-# INLINE getPixel #-}

    RGBImage image `unsafeGetPixel` Point x y =
        let coords = Z :. y :. x
        in RGBPixel {
              rgbRed = image `unsafeIndex` (coords :. 0)
            , rgbGreen = image `unsafeIndex` (coords :. 1)
            , rgbBlue = image `unsafeIndex` (coords :. 2)
        }
    {-# INLINE unsafeGetPixel #-}
    
instance I.Pixel RGBPixel Word8 where
    pixToValues (RGBPixel r g b) = [r, g, b]
    {-# INLINE pixToValues #-}
    
    valuesToPix [r, g, b] = RGBPixel r g b
    {-# INLINE valuesToPix #-}
    
    RGBPixel r g b `pixApply` f = RGBPixel (f r) (f g) (f b)
    {-# INLINE pixApply #-}
    
-- | Returns the shape of an image of the given size.
imageShape :: Size -> DIM3
imageShape (Size w h) = Z :. h :. w :. 3
{-# INLINE imageShape #-}