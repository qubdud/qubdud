import 'package:dio/dio.dart';

Response<dynamic> mockNewsResponse(RequestOptions options) {
  if (options.path == '/news') {
    return Response(
      requestOptions: options,
      statusCode: 200,
      data: [
        {
          "id": "1",
          "title": "New Feature Released",
          "content":
              "In the early 20th century, Dubai developed into a significant regional and international trade hub, emphasizing tourism and luxury.[10] Dubai has been a center for regional and international trade since the early 20th century, and its economy relies on revenues from trade, tourism, aviation, real estate, and financial services.[11][12][13][14] Oil revenue helped accelerate the development of the city. However, oil production contributed less than 1 percent to the emirate's GDP in 2018.[15] Due to financial secrecy, low taxes, and valuable real estate, Dubai is an appealing destination for money launderers, criminals, corrupt political figures and sanctioned businesspeople to launder or hide money.",
          "publication_at": "2024-01-01",
          "image_url": "https://upload.wikimedia.org/wikipedia/commons/f/f1/Burj_Al_Arab_%40_Madinat_Jumeirah_%40_Dubai_%2815851725086%29.jpg",
          "navigationTarget": "feature_page",
          "html": "",
          "pdf": "",
          "is_new": true,
          "is_pin": false
        },
        {
          "id": "2",
          "title": "System Maintenance",
          "content": "Scheduled maintenance on 2024-02-01.",
          "publication_at": "2024-01-10",
          "image_url": "",
          "navigationTarget": "maintenance_page",
          "html": "",
          "pdf": "",
          "is_new": true,
          "is_pin": true
        },
        {
          "id": "3",
          "title": "Discount Offer",
          "content": "Limited-time discount on all products!",
          "publication_at": "2024-01-15",
          "image_url": "",
          "navigationTarget": "offers_page",
          "html": "",
          "pdf": "",
          "is_new": false,
          "is_pin": false
        },
        {
          "id": "4",
          "title": "Company Event",
          "content": "Join us for our annual company event.",
          "publication_at": "2024-02-05",
          "image_url": "",
          "navigationTarget": "events_page",
          "html": "",
          "pdf": "",
          "is_new": false,
          "is_pin": true
        },
        {
          "id": "5",
          "title": "Product Launch",
          "content": "Introducing our latest product.",
          "publication_at": "2024-02-10",
          "image_url": "",
          "navigationTarget": "product_page",
          "html": "",
          "pdf": "",
          "is_new": true,
          "is_pin": false
        }
      ],
    );
  }

  return Response(
    requestOptions: options,
    statusCode: 400,
    data: {
      "status": "error",
      "message": "Invalid request data",
    },
  );
}
