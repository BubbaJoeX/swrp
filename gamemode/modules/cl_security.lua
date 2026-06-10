--[[---------------------------------------------------------------------------
    Security camera render targets (client)
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Security = SWGRP.Security or {}

local SEC = SWGRP.Security
SEC.RenderTargets = SEC.RenderTargets or {}

function SEC.GetRT( entIndex )
	local key = "swgrp_cam_" .. entIndex
	if not SEC.RenderTargets[key] then
		SEC.RenderTargets[key] = GetRenderTarget( key, 512, 512 )
	end
	return SEC.RenderTargets[key]
end

function SEC.RenderCameraView( camEnt )
	if not IsValid( camEnt ) then return end

	local rt = SEC.GetRT( camEnt:EntIndex() )
	local old = render.GetRenderTarget()
	render.SetRenderTarget( rt )
	render.Clear( 0, 0, 0, 255 )

	local view = {
		origin = camEnt:GetCamPos(),
		angles = camEnt:GetCamAng(),
		x = 0,
		y = 0,
		w = 512,
		h = 512,
		fov = 75,
		drawviewmodel = false,
		drawhud = false,
	}

	render.RenderView( view )
	render.SetRenderTarget( old )
end

net.Receive( "SWGRP_SecuritySync", function()
	local count = net.ReadUInt( 8 )
	SEC.CameraIndices = {}
	for _ = 1, count do
		table.insert( SEC.CameraIndices, net.ReadUInt( 16 ) )
	end
end )
