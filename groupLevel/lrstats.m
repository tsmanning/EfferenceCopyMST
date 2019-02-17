function [amplrstats,offlrstats,bandlrstats] = lrstats(AmpStats,OffStats,BandStats)
% amplitude
normp = signrank(AmpStats.vals(1:101,1),AmpStats.vals(102:202,1));
normdiff = median(AmpStats.vals(1:101,1)-AmpStats.vals(102:202,1),'omitnan');

simp = signrank(AmpStats.vals(1:101,2),AmpStats.vals(102:202,2));
simdiff = median(AmpStats.vals(1:101,2)-AmpStats.vals(102:202,2),'omitnan');

stabp = signrank(AmpStats.vals(1:101,3),AmpStats.vals(102:202,3));
stabdiff = median(AmpStats.vals(1:101,3)-AmpStats.vals(102:202,3),'omitnan');

amplrstats = [normp, normdiff; simp, simdiff; stabp stabdiff];

clear normp normdiff simp simdiff stabp stabdiff

% offset
normp = signrank(OffStats.vals(1:101,1),OffStats.vals(102:202,1));
normdiff = median(OffStats.vals(1:101,1)-OffStats.vals(102:202,1),'omitnan');

simp = signrank(OffStats.vals(1:101,2),OffStats.vals(102:202,2));
simdiff = median(OffStats.vals(1:101,2)-OffStats.vals(102:202,2),'omitnan');

stabp = signrank(OffStats.vals(1:101,3),OffStats.vals(102:202,3));
stabdiff = median(OffStats.vals(1:101,3)-OffStats.vals(102:202,3),'omitnan');

offlrstats = [normp, normdiff; simp, simdiff; stabp stabdiff];

clear normp normdiff simp simdiff stabp stabdiff

% bandswidth
normp = signrank(BandStats.vals(1:101,1),BandStats.vals(102:202,1));
normdiff = median(BandStats.vals(1:101,1)-BandStats.vals(102:202,1),'omitnan');

simp = signrank(BandStats.vals(1:101,2),BandStats.vals(102:202,2));
simdiff = median(BandStats.vals(1:101,2)-BandStats.vals(102:202,2),'omitnan');

stabp = signrank(BandStats.vals(1:101,3),BandStats.vals(102:202,3));
stabdiff = median(BandStats.vals(1:101,3)-BandStats.vals(102:202,3),'omitnan');

bandlrstats = [normp, normdiff; simp, simdiff; stabp stabdiff];
end