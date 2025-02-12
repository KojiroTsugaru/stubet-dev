//
//  TimeLocationDetailPanel.swift
//  Stubet
//
//  Created by KJ on 12/6/24.
//

import SwiftUI
import MapKit

struct TimeLocationDetailsPanel: View {
    
    let betItem: any BetItem
    @State private var region: MKCoordinateRegion
    private var annotatedCoordinate: IdentifiableCoordinate
    
    init(betItem: any BetItem) {
        self.betItem = betItem        // Initialize the region with selectedCoordinates
        let initialCoordinate = CLLocationCoordinate2D(latitude: betItem.location.latitude, longitude: betItem.location.longitude)
        self._region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: betItem.location.latitude, longitude: betItem.location.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
        self.annotatedCoordinate = IdentifiableCoordinate(coordinate: initialCoordinate)
    }
    
    var body: some View {
        VStack() {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 20))
                Spacer()
                Text(betItem.formattedDeadline)
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.leading)
                Spacer()
                Text(betItem.deadlineTimeRemaining)
                    .font(.system(size: 16))
                    .foregroundColor(.orange)
            }
            .padding(.horizontal)
            .padding(.top, 20)

            // Location Section
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(.orange)
                    .font(.system(size: 20))
                Spacer()
                VStack(alignment: .center, spacing: 4) {
                    Text(betItem.location.name)
                        .font(.system(size: 16, weight: .semibold))
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 10)

            // Map Section
            Map(
                coordinateRegion: $region,
                interactionModes: .zoom,
                annotationItems: [annotatedCoordinate]
            ) { item in
                MapMarker(coordinate: item.coordinate, tint: .red)
            }
            .frame(height: 200)
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.top, 10)


            // Confirmation Button
            Button(action: {
                // Action to open external map
                openMaps()
            }) {
                Text("マップで確認する")
                    .font(.system(size: 16, weight: .semibold))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
    
    private func openMaps() {
        let latitude = annotatedCoordinate.coordinate.latitude
        let longitude = annotatedCoordinate.coordinate.longitude
        
        if UIApplication.shared.canOpenURL(URL(string: "comgooglemaps://")!) {
            // Open Google Maps
            let googleMapsURL = URL(string: "comgooglemaps://?q=\(latitude),\(longitude)&zoom=14")!
            UIApplication.shared.open(googleMapsURL, options: [:], completionHandler: nil)
        } else {
            // Fallback to Apple Maps
            let appleMapsURL = URL(string: "http://maps.apple.com/?q=\(latitude),\(longitude)&z=14")!
            UIApplication.shared.open(appleMapsURL, options: [:], completionHandler: nil)
        }
    }
}

//struct TimeLocationDetailsPanel_Previews: PreviewProvider {
//    static var previews: some View {
//        TimeLocationDetailsPanel(betItem: )
//    }
//}
