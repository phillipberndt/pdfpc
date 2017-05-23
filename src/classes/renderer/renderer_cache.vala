/**
 * Storage for the cached views of a presentation
 *
 * This file is part of pdfpc.
 *
 * Copyright (C) 2017 Phillip Berndt <phillip.berndt@googlemail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

namespace pdfpc.Renderer {
    /**
     * Class representing a cached view
     */
    public class CachedView: Object {
        // Note: This is its own class to allow to extend this to multi-threaded
        // preloading (which requires a lock per surface) in the future.
        public Cairo.ImageSurface? surface;
    }

    /**
     * Class for providing storage for the cached views associated with a presentation
     */
    public class RendererCache: Object {
        protected Gee.HashMap<Array<int>, Array<CachedView>> renderer_cache { get; protected set; }
        protected Gee.TreeSet<Array<int>> protected_resolutions;

        public RendererCache() {
            this.renderer_cache = new Gee.HashMap<Array<int>, Array<CachedView>>(
                    (K) => { return K.index(0) * 10000 + K.index(1); },
                    (V1, V2) => { return V1.index(0) == V2.index(0) && V1.index(1) == V2.index(1); }
                );
            this.protected_resolutions = new Gee.TreeSet<Array<int>>((V1, V2) => {
                    int v1 = V1.index(0) * 10000 + V1.index(1);
                    int v2 = V2.index(0) * 10000 + V1.index(1);
                    if(v1 == v2) {
                        return 0;
                    }
                    return v1 < v2 ? -1 : 1;
            });
        }

        public void protect_resolution(int width, int height) {
            var key = new Array<int>();
            key.append_val(width);
            key.append_val(height);
            protected_resolutions.add(key);
        }

        public CachedView get_view(int width, int height, int slide_id) {
            var key = new Array<int>();
            key.append_val(width);
            key.append_val(height);

            var resolution_views = renderer_cache.get(key);
            if(resolution_views == null) {
                resolution_views = new Array<CachedView>();
                renderer_cache.set(key, resolution_views);
            }
            while(resolution_views.length < slide_id + 1) {
                resolution_views.append_val(new CachedView());
            }

            return resolution_views.index(slide_id);
        }

        public void invalidate_caches(int valid_slides_lower, int valid_slides_upper) {
            foreach(Array<int> key in renderer_cache.keys) {
                if(!protected_resolutions.contains(key)) {
                    invalidate_cache(key.index(0), key.index(1), valid_slides_lower, valid_slides_upper);
                }
            }
        }

        public void invalidate_cache(int width, int height, int valid_slides_lower, int valid_slides_upper) {
            var key = new Array<int>();
            key.append_val(width);
            key.append_val(height);

            var resolution_views = renderer_cache.get(key);
            if(resolution_views == null) {
                return;
            }

            for(int i=0; i<valid_slides_lower && i<resolution_views.length; i++) {
                var cached_view = resolution_views.index(i);
                cached_view.surface = null;
            }

            for(int i=valid_slides_upper+1; i<resolution_views.length; i++) {
                var cached_view = resolution_views.index(i);
                cached_view.surface = null;
            }
        }
    }
}
