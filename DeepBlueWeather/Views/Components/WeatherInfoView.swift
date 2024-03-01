//
//  WeatherInfoView.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 26.02.24.
//

import SwiftUI

struct WeatherInfoView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "sun.max.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .foregroundColor(.yellow)
                    .opacity(70)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            
                            self.iconOpacity = 1.0
                        }
                    }
                
                Text("Temperature: 23°C")
                    .font(.title)
                    .foregroundColor(.white)
                    .opacity(70)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            
                            self.textOpacity = 1.0
                        }
                    }
            }
            
            HStack {
                Image(systemName: "wind")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .foregroundColor(.white)
                    .opacity(70)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            
                            self.iconOpacity = 1.0
                        }
                    }
                
                Text("Wind Speed: 5 mph")
                    .foregroundColor(.white)
                    .opacity(70)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            self.textOpacity = 1.0
                        }
                    }
            }
            
            HStack {
                Image(systemName: "eye")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .foregroundColor(.white)
                    .opacity(70)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            self.iconOpacity = 1.0
                        }
                    }
                
                Text("Visibility: 10 miles")
                    .foregroundColor(.white)
                    .opacity(70)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            self.textOpacity = 1.0
                        }
                    }
            }
            
            HStack {
                Image(systemName: "thermometer.sun.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .foregroundColor(.white)
                    .opacity(70)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            self.iconOpacity = 1.0
                        }
                    }
                
                Text("Water Temperature: 25°C")
                    .foregroundColor(.white)
                    .opacity(70)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            self.textOpacity = 1.0
                        }
                    }
            }
            
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .foregroundColor(.white)
                    .opacity(70)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            self.iconOpacity = 1.0
                        }
                    }
                
                Text("Wave Height: 2 feet")
                    .foregroundColor(.white)
                    .opacity(70)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            self.textOpacity = 1.0
                        }
                    }
            }
            
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .foregroundColor(.white)
                    .opacity(70)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            self.iconOpacity = 1.0
                        }
                    }
                
                Text("Currents: Mild")
                    .foregroundColor(.white)
                    .opacity(70)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            self.textOpacity = 1.0
                        }
                    }
            }
            
            HStack {
                Image(systemName: "drop.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .foregroundColor(.white)
                    .opacity(70)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            self.iconOpacity = 1.0
                        }
                    }
                
                Text("Tide: Incoming")
                    .foregroundColor(.white)
                    .opacity(70)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            self.textOpacity = 1.0
                        }
                    }
            }
            
            
        }
        .padding()
        .background(Color.blue) // Example background color
        .cornerRadius(10)
    }
    
    // State variables for controlling opacity animations
    @State private var iconOpacity = 0.0
    @State private var textOpacity = 0.0
}

struct WeatherInfoView_Previews: PreviewProvider {
    static var previews: some View {
        WeatherInfoView()
    }
}


