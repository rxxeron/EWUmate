-- Disable maintenance mode
UPDATE public.app_config 
SET is_enabled = false 
WHERE key = 'maintenance_mode';
